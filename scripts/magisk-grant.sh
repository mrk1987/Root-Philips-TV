#!/system/bin/sh
# Run as root: add permanent allow policy for shell (uid 2000) in Magisk's DB
LOG=/data/local/tmp/magisk-grant.log
: > "$LOG"
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

log "id: $(id)"
log "selinux: $(getenforce)"
log "magisk version: $(/sbin/magisk -v 2>&1)"
log "--- /data/adb/magisk ---"
ls -la /data/adb/magisk/ >> "$LOG" 2>&1

# policies: allow (policy=2), not time-limited (until=0) for shell uid
/sbin/magisk --sqlite "INSERT OR REPLACE INTO policies (uid, policy, until, logging, notification) VALUES(2000, 2, 0, 1, 0);" >> "$LOG" 2>&1
log "sqlite insert exit=$?"
/sbin/magisk --sqlite "SELECT * FROM policies;" >> "$LOG" 2>&1
log "=== done ==="
exit 0
