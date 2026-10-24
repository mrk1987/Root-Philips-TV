#!/system/bin/sh
# Populate /data/adb/magisk from the Magisk 25.2 APK. The TV was rooted by patching boot
# on-device, so the Magisk app never set this directory up; magiskd then aborts post-fs-data
# with "Magisk environment incomplete" and service.d scripts cannot run (missing busybox).
set -e
SRC=/data/local/tmp/magisk-env
DST=/data/adb/magisk
mkdir -p "$DST"
cp "$SRC/libbusybox.so"      "$DST/busybox"
cp "$SRC/libmagisk32.so"     "$DST/magisk32"
cp "$SRC/libmagiskinit.so"   "$DST/magiskinit"
cp "$SRC/libmagiskboot.so"   "$DST/magiskboot"
cp "$SRC/libmagiskpolicy.so" "$DST/magiskpolicy"
cp "$SRC/util_functions.sh"  "$DST/util_functions.sh"
cp "$SRC/boot_patch.sh"      "$DST/boot_patch.sh"
chmod 755 "$DST/busybox" "$DST/magisk32" "$DST/magiskinit" "$DST/magiskboot" "$DST/magiskpolicy"
chmod 644 "$DST/util_functions.sh" "$DST/boot_patch.sh"
ls -l "$DST"
"$DST/busybox" echo busybox-ok
