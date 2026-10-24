#!/system/bin/sh
# Stop Inscape's native ACR fingerprinting daemon on every boot.
# The Android client package tv.inscape.tvclient.inscapeacr is already disabled;
# this stops the init service that still runs independently of it.
PATH=/system/bin:/system/xbin
export PATH
stop inscape_fp
