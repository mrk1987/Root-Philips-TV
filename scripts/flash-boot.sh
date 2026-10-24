#!/system/bin/sh
# Run as root via:
#   /data/local/tmp/rootexec /system/bin/sh /data/local/tmp/flash-boot.sh
#
# Writes the verified Magisk boot image to /dev/block/mmcblk0p5.
# Refuses unless the current boot is still the known stock image.
# Verifies the image, writes it, syncs, reads back and compares.
# On a read-back mismatch it restores the 20 MB stock backup.
# DOES NOT REBOOT.

BOOTDEV=/dev/block/mmcblk0p5
IMG=/data/local/tmp/magisk/new-boot.img
BACKUP=/data/local/tmp/boot-stock.img
LOG=/data/local/tmp/flash-boot.log

STOCK_SHA1=737cc3fff2e4e0885f39cdabd1418bb3ff62af74
PATCHED_SHA1=5beaa29c84d3f583f911324a3d2b95505ad310ae
STOCK_BYTES=12526888
PATCHED_BYTES=12734464

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

: > "$LOG"
log "=== flash-boot start ==="
log "id: $(id)"
log "selinux: $(getenforce)"

# 1) Boot partition magic
MAGIC=$(dd if=$BOOTDEV bs=8 count=1 2>/dev/null)
log "boot magic: $MAGIC"
if [ "$MAGIC" != "ANDROID!" ]; then
  log "FATAL: boot magic mismatch; refusing"
  exit 10
fi

# 2) Current boot must still be the known stock image
CUR=$(dd if=$BOOTDEV bs=$STOCK_BYTES count=1 2>/dev/null | sha1sum | cut -d' ' -f1)
log "current boot head sha1: $CUR"
if [ "$CUR" != "$STOCK_SHA1" ]; then
  log "FATAL: current boot is not the known stock image; refusing"
  exit 11
fi

# 3) Image must be the verified patched image
IMGS=$(stat -c %s $IMG 2>/dev/null)
IMGC=$(sha1sum $IMG | cut -d' ' -f1)
log "image: size=$IMGS sha1=$IMGC"
if [ "$IMGS" != "$PATCHED_BYTES" ] || [ "$IMGC" != "$PATCHED_SHA1" ]; then
  log "FATAL: image is not the verified patched image; refusing"
  exit 12
fi

# 4) Write
log ">>> writing $IMG to $BOOTDEV"
dd if=$IMG of=$BOOTDEV bs=4096 2>>"$LOG"
log "dd exit=$?"
sync

# 5) Read-back verification
RB=$(dd if=$BOOTDEV bs=$PATCHED_BYTES count=1 2>/dev/null | sha1sum | cut -d' ' -f1)
log "read-back sha1: $RB"
if [ "$RB" != "$PATCHED_SHA1" ]; then
  log "FATAL: read-back mismatch; restoring the 20 MB stock backup"
  dd if=$BACKUP of=$BOOTDEV bs=4096 2>>"$LOG"
  sync
  log "restore done; NOT rebooting"
  exit 13
fi

log "=== SUCCESS: boot partition written and verified. Not rebooting. ==="
exit 0
