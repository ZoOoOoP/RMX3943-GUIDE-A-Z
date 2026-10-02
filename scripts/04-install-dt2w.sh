#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
KIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ADB_BIN=${ADB_BIN:-adb}

adb_root() {
    "$ADB_BIN" root
    "$ADB_BIN" wait-for-device
}

adb_root

# Activate the static DT2W overlay already included in this PHH/Lineage GSI.
"$ADB_BIN" shell setprop persist.sys.overlay.dt2w true

# Make only the vendor overlay writable. On its first activation adb remount
# asks for one reboot before writes become possible.
"$ADB_BIN" remount || true
if ! "$ADB_BIN" shell 'touch /vendor/.rmx3943-dt2w-write-test && rm -f /vendor/.rmx3943-dt2w-write-test'; then
    "$ADB_BIN" reboot
    "$ADB_BIN" wait-for-device
    adb_root
    "$ADB_BIN" remount || true
fi

"$ADB_BIN" push "$KIT_DIR/dt2w/init.rmx3943-dt2w.rc" \
    /vendor/etc/init/init.rmx3943-dt2w.rc
"$ADB_BIN" shell 'chown root:root /vendor/etc/init/init.rmx3943-dt2w.rc; chmod 0644 /vendor/etc/init/init.rmx3943-dt2w.rc; restorecon /vendor/etc/init/init.rmx3943-dt2w.rc'

# This data repository is deliberately used instead of /vendor/usr: on the
# tested GSI, SELinux blocks system_server from reading newly overlaid vendor
# input files even when their file labels are correct.
"$ADB_BIN" shell 'mkdir -p /data/system/devices/idc /data/system/devices/keylayout; chown -R system:system /data/system/devices; chmod 0755 /data/system/devices /data/system/devices/idc /data/system/devices/keylayout'
"$ADB_BIN" push "$KIT_DIR/dt2w/touchpanel.idc" \
    /data/system/devices/idc/touchpanel.idc
"$ADB_BIN" push "$KIT_DIR/dt2w/rmx3943_touchpanel.kl" \
    /data/system/devices/keylayout/rmx3943_touchpanel.kl
"$ADB_BIN" shell 'chown system:system /data/system/devices/idc/touchpanel.idc /data/system/devices/keylayout/rmx3943_touchpanel.kl; chmod 0644 /data/system/devices/idc/touchpanel.idc /data/system/devices/keylayout/rmx3943_touchpanel.kl; restorecon -RF /data/system/devices'

"$ADB_BIN" reboot
"$ADB_BIN" wait-for-device
"$ADB_BIN" shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
adb_root

"$ADB_BIN" shell 'printf "overlay="; cmd overlay lookup android android:bool/config_supportDoubleTapWake; printf "driver="; cat /proc/touchpanel/double_tap_enable; dumpsys input | grep -A12 "Path: /dev/input/event2"'
