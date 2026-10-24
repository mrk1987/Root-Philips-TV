#!/system/bin/sh
# Resize zram from the firmware's 100 MB to 256 MB on every boot.
# Runs from /data/adb/service.d (Magisk, late_start). Idempotent: exits if already sized.
PATH=/system/bin:/system/xbin
export PATH

Z=/dev/block/zram0
WANT=268435456
cur=$(cat /sys/block/zram0/disksize 2>/dev/null)
[ "$cur" = "$WANT" ] && exit 0

# Let the firmware's one-shot zram service finish first.
i=0
while [ "$(getprop init.svc.zram-svc)" = "running" ] && [ "$i" -lt 30 ]; do
    sleep 1
    i=$((i + 1))
done

swapoff "$Z" 2>/dev/null
echo 1 > /sys/block/zram0/reset 2>/dev/null || exit 0
echo "$WANT" > /sys/block/zram0/disksize || exit 0
mkswap "$Z" >/dev/null 2>&1
swapon "$Z"
