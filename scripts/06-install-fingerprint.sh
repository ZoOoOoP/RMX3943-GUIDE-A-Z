#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
KIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ADB_BIN=${ADB_BIN:-adb}
WORK_DIR="$KIT_DIR/work/fingerprint"
TOOLS_DIR="$KIT_DIR/tools"

RRO_DEVICE=/system/product/overlay/framework-res__lineage_gsi_arm64_gN__auto_generated_rro_product.apk
RRO_SHA256=a085389b07d81ad10a3ca465ecb3bb8c7a6e50d7df378e116f3631de147bd95b
LINEAGE_VERSION=22.2-20250621-UNOFFICIAL-gsi_arm64_gN
APKTOOL_VERSION=2.10.0
APKTOOL_SHA256=c0350abbab5314248dfe2ee0c907def4edd14f6faef1f5d372d3d4abd28f0431
APKTOOL_JAR="$TOOLS_DIR/apktool_$APKTOOL_VERSION.jar"

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

adb_root() {
    "$ADB_BIN" root
    "$ADB_BIN" wait-for-device
}

sha256_of() {
    shasum -a 256 "$1" | awk '{print $1}'
}

# Java and Android SDK build-tools are needed to rebuild and sign the RRO.
if [ -z "${JAVA_HOME:-}" ] && [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
fi
JAVA_BIN=${JAVA_HOME:+$JAVA_HOME/bin/}java
SDK_DIR=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}
BUILD_TOOLS=$(ls -d "$SDK_DIR"/build-tools/* 2>/dev/null | sort -V | tail -n 1)
[ -n "$BUILD_TOOLS" ] || die "build-tools Android introuvables dans $SDK_DIR"
for tool in "$JAVA_BIN" "${JAVA_HOME:+$JAVA_HOME/bin/}keytool" "$BUILD_TOOLS/zipalign" "$BUILD_TOOLS/apksigner" curl shasum perl; do
    command -v "$tool" >/dev/null 2>&1 || die "Commande manquante: $tool"
done
"$JAVA_BIN" -version 2>&1 | grep -q -E 'version "(1[7-9]|[2-9][0-9])' || die "Java 17 ou plus requis (définir JAVA_HOME)"

adb_root

[ "$("$ADB_BIN" shell getprop ro.product.vendor.device | tr -d '\r')" = RE6092 ] || die "Appareil inattendu: RMX3943 / RE6092 requis"
[ "$("$ADB_BIN" shell getprop ro.lineage.version | tr -d '\r')" = "$LINEAGE_VERSION" ] || die "GSI inattendue: $LINEAGE_VERSION requise"

# Read the original GSI overlay, not a copy already bound over it.
"$ADB_BIN" shell "while grep -q ' $RRO_DEVICE ' /proc/mounts; do umount -l $RRO_DEVICE; done"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$TOOLS_DIR"
"$ADB_BIN" pull "$RRO_DEVICE" "$WORK_DIR/original.apk"
[ "$(sha256_of "$WORK_DIR/original.apk")" = "$RRO_SHA256" ] || die "Overlay GSI différent de celui validé"
"$ADB_BIN" pull /system/framework/framework-res.apk "$WORK_DIR/framework-res.apk"

if [ ! -f "$APKTOOL_JAR" ]; then
    curl -fL -o "$APKTOOL_JAR" "https://github.com/iBotPeaches/Apktool/releases/download/v$APKTOOL_VERSION/apktool_$APKTOOL_VERSION.jar"
fi
[ "$(sha256_of "$APKTOOL_JAR")" = "$APKTOOL_SHA256" ] || die "Empreinte apktool invalide: $APKTOOL_JAR"

# Rebuild the same overlay with only config_biometric_sensors emptied.
"$JAVA_BIN" -jar "$APKTOOL_JAR" if -p "$WORK_DIR/framework" "$WORK_DIR/framework-res.apk"
"$JAVA_BIN" -jar "$APKTOOL_JAR" d -f -p "$WORK_DIR/framework" -o "$WORK_DIR/decoded" "$WORK_DIR/original.apk"
perl -0pi -e 's#<string-array name="config_biometric_sensors">\s*<item>0:2:15</item>\s*</string-array>#<string-array name="config_biometric_sensors" />#' \
    "$WORK_DIR/decoded/res/values/arrays.xml"
grep -q '<string-array name="config_biometric_sensors" />' "$WORK_DIR/decoded/res/values/arrays.xml" || die "Correctif config_biometric_sensors non appliqué"
"$JAVA_BIN" -jar "$APKTOOL_JAR" b -p "$WORK_DIR/framework" -o "$WORK_DIR/unsigned.apk" "$WORK_DIR/decoded"
"$BUILD_TOOLS/zipalign" -f 4 "$WORK_DIR/unsigned.apk" "$WORK_DIR/aligned.apk"
"${JAVA_HOME:+$JAVA_HOME/bin/}keytool" -genkeypair -keystore "$WORK_DIR/key.jks" -storepass rmx3943 -keypass rmx3943 \
    -alias rro -keyalg RSA -keysize 2048 -validity 10000 -dname CN=rmx3943-fingerprint >/dev/null 2>&1
JAVA_HOME=${JAVA_HOME:-} "$BUILD_TOOLS/apksigner" sign --ks "$WORK_DIR/key.jks" --ks-pass pass:rmx3943 \
    --out "$WORK_DIR/rmx3943-fingerprint-rro.bin" "$WORK_DIR/aligned.apk"

# Make only the vendor overlay writable. On its first activation adb remount
# asks for one reboot before writes become possible.
"$ADB_BIN" remount || true
if ! "$ADB_BIN" shell 'touch /vendor/.rmx3943-fp-write-test && rm -f /vendor/.rmx3943-fp-write-test'; then
    "$ADB_BIN" reboot
    "$ADB_BIN" wait-for-device
    adb_root
    "$ADB_BIN" remount || true
fi

"$ADB_BIN" push "$KIT_DIR/fingerprint/android.hardware.fingerprint.xml" \
    /vendor/etc/permissions/android.hardware.fingerprint.xml
"$ADB_BIN" push "$WORK_DIR/rmx3943-fingerprint-rro.bin" \
    /vendor/overlay/rmx3943-fingerprint-rro.bin
"$ADB_BIN" push "$KIT_DIR/fingerprint/init.rmx3943-fingerprint.rc" \
    /vendor/etc/init/init.rmx3943-fingerprint.rc
"$ADB_BIN" shell 'for f in /vendor/etc/permissions/android.hardware.fingerprint.xml /vendor/overlay/rmx3943-fingerprint-rro.bin /vendor/etc/init/init.rmx3943-fingerprint.rc; do chown root:root $f; chmod 0644 $f; restorecon $f; done'

"$ADB_BIN" reboot
"$ADB_BIN" wait-for-device
"$ADB_BIN" shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
adb_root

"$ADB_BIN" shell "printf 'feature='; pm list features | grep -c android.hardware.fingerprint; printf 'mount='; grep -c ' $RRO_DEVICE ' /proc/mounts; dumpsys fingerprint | grep -E 'sensorId|Current operation|Pending operations'"
