#!/system/bin/sh
# Magisk's own environment is incomplete on this TV ("environment incomplete", no busybox),
# so never rely on the inherited PATH.
PATH=/system/bin:/system/xbin
export PATH
# Boot guard for package experiments on the rooted Philips TPM171E.
# Installed at /data/adb/service.d/50-bootguard.sh; Magisk runs it as root on every boot.
#
# Workflow:
#   1. Before disabling package(s), write their names (space-separated) to
#      /data/local/tmp/bootguard/pending and write 1 to /data/local/tmp/bootguard/armed.
#   2. Reboot. On that first boot the guard clears "armed" and leaves "pending" alone.
#   3. If the TV booted normally, truncate "pending" (no rm needed: use `: > pending`).
#      If it boot-looped, the next boot cycle re-enables every listed package.
#
# Limits: the guard only works if init reaches late_start service and package manager
# answers. It is a convenience; the USB upgrade_loader remains the real recovery net.

BG=/data/local/tmp/bootguard
mkdir -p "$BG"
[ -f "$BG/pending" ] || exit 0
pkgs=$(cat "$BG/pending" 2>/dev/null)
[ -n "$pkgs" ] || exit 0
if [ "$(cat "$BG/armed" 2>/dev/null)" = "1" ]; then
    : > "$BG/armed"
    echo "$(date +%s) first boot after change, pending $pkgs" >> "$BG/log"
    exit 0
fi

# Package manager is not up yet at the late_start service stage, so retry for up to five
# minutes. Only a fully successful run clears pending; failures keep it for the next boot.
failed=
for pkg in $pkgs; do
    i=0
    ok=
    while [ "$i" -lt 60 ]; do
        if /system/bin/pm enable --user 0 "$pkg" >/dev/null 2>&1; then
            ok=1
            break
        fi
        i=$((i + 1))
        sleep 5
    done
    if [ -n "$ok" ]; then
        echo "$(date +%s) re-enabled $pkg (attempt $i)" >> "$BG/log"
    else
        echo "$(date +%s) FAILED to re-enable $pkg after $i attempts" >> "$BG/log"
        failed=1
    fi
done
[ -z "$failed" ] && : > "$BG/pending"
