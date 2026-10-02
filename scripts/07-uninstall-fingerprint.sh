#!/bin/sh
set -eu

ADB_BIN=${ADB_BIN:-adb}

"$ADB_BIN" root
"$ADB_BIN" wait-for-device
"$ADB_BIN" remount || true
"$ADB_BIN" shell 'rm -f /vendor/etc/init/init.rmx3943-fingerprint.rc /vendor/overlay/rmx3943-fingerprint-rro.bin /vendor/etc/permissions/android.hardware.fingerprint.xml'
"$ADB_BIN" reboot
