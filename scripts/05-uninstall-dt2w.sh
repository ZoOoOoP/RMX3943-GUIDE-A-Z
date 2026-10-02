#!/bin/sh
set -eu

ADB_BIN=${ADB_BIN:-adb}

"$ADB_BIN" root
"$ADB_BIN" wait-for-device
"$ADB_BIN" shell setprop persist.sys.overlay.dt2w false
"$ADB_BIN" remount || true
"$ADB_BIN" shell 'rm -f /vendor/etc/init/init.rmx3943-dt2w.rc /data/system/devices/idc/touchpanel.idc /data/system/devices/keylayout/rmx3943_touchpanel.kl; rmdir /data/system/devices/idc /data/system/devices/keylayout /data/system/devices 2>/dev/null || true'
"$ADB_BIN" reboot
