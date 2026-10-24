# Work after permanent root

These were separate changes after the successful root flash. They are not prerequisites for rooting
or enabling A2DP. The scripts are historical source from the installed setup, not a universal optimizer.

## Magisk script environment

An empty `/data/adb/magisk` let su work but prevented Magisk script stages from running. Install the
ARMv7 files extracted from Magisk 25.2 with `scripts/magisk-env-install.sh`; see the main guide.
After repair and reboot, script stages worked and the environment-incomplete abort disappeared.

## Package-change boot guard

`scripts/50-bootguard.sh` was installed at `/data/adb/service.d/50-bootguard.sh` (mode 755).
Before a reversible package experiment, put the package names, space-separated, in
`/data/local/tmp/bootguard/pending` and `1` in `.../armed`. First boot clears armed. A following boot
attempts `pm enable --user 0` for each pending package, retrying up to 60 times at five-second intervals
per package, and clears pending only after all succeed. After a successful first boot, clear pending
manually. Single-package and seven-package cases were tested.

This cannot repair early boot failure or a dead package manager. It is not a replacement for a
stock backup and USB recovery, and does not make disabling core TV packages safe.

## Memory and background service changes

- `scripts/60-zram-resize.sh`: recorded resize from 100 MB to 256 MB, installed in Magisk service.d.
- `scripts/70-stop-inscape.sh`: stops the native Inscape fingerprint service at boot.

Inspect the scripts and confirm the same kernel/interfaces/services before reusing them. No
overclock was performed. The installed kernel exposed no useful cpufreq/devfreq controls in the
investigation; root by itself does not establish overclocking support.

## App compilation

I ran `cmd package compile -m speed PACKAGE` over selected installed apps. Already-compiled apps
were skipped without `-f`. The initial pass took about six minutes. For a long batch started through
the Python ADB helper, a detached `setsid sh SCRIPT > LOG 2>&1 &` and a short initial session delay
were needed; a silent call could hit the helper's 120-second timeout. No private installed-app list
is published. This compilation was unrelated to establishing root or Bluetooth pairing.

## Subsequent Bluetooth work

The A2DP overlay, missing pairing consent, volume handling and blue-button panel are documented in
[BT-On-Philips-TV](https://github.com/mrk1987/BT-On-Philips-TV). The panel requires no root to run once
the firmware profile has been enabled; root was needed for the component change on this build.
