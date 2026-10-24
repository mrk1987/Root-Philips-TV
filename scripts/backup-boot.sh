#!/system/bin/sh
# Run as root via: /data/local/tmp/rootexec /system/bin/sh /data/local/tmp/backup-boot.sh
# Reads the 20 MB boot partition and prints size + hashes for verification.
BOOTDEV=/dev/block/mmcblk0p5
BACKUP=/data/local/tmp/boot-stock.img

echo "MAGIC=$(dd if=$BOOTDEV bs=8 count=1 2>/dev/null)"
dd if=$BOOTDEV of=$BACKUP bs=4096 count=5120 2>/dev/null
sync
echo "BACKUP_SIZE=$(stat -c %s $BACKUP)"
echo "BACKUP_SHA1=$(sha1sum $BACKUP | cut -d' ' -f1)"
echo "STOCK_HEAD_SHA1=$(dd if=$BOOTDEV bs=12526888 count=1 2>/dev/null | sha1sum | cut -d' ' -f1)"
