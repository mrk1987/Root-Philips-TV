> Historical session record, sanitized for publication. Read [the final guide](../README.md)
> for the completed procedure. Early "unchanged boot", "stop here", "pending DRM" and "empty Magisk
> environment needs no action" statements describe earlier stages, not the final state. The final
> guide incorporates the later flash, Magisk environment repair and Netflix playback result.
> Local workspace artifact paths are historical references; binary/private artifacts are not distributed.

# Rooting the bedroom TV: risk assessment

Written 2026-10-22 for the Philips TPM171E (board `PH7M_EU_5596`, MediaTek MT5891, Android 8.0, firmware
`TPM171E_R.107.001.143.000`). Nothing has been done; this is research only.

> **Update 2026-10-24:** Executed and **rooted**. The route changed from the firmware/Docker method
> below to patching the TV's own boot partition on-device with Magisk 25.2's own `boot_patch.sh`; the
> result is byte-identical to the proven reference (`5beaa29c…`), was flashed to `/boot`, read back
> identical, and `su -c id` returns `u:r:magisk:s0` after a payload-free cold reboot. Full record,
> hashes and rollback: `ROOT-WORKLOG.md`.

## Bottom line

**It can be done, and the documented method avoids the step that bricks TVs. But it gains you little that you
don't already have, and the failure case costs a full reflash and a day's setup.** My recommendation is not to root
now. If you want to do it anyway as a project, the plan below keeps the risk as low as it gets.

## Sources read

- **[saidsurucu/philips-tpm171e-root](https://github.com/saidsurucu/philips-tpm171e-root)**: README, the author's own
  session notes and every script. A complete, working root on a 49PUS7503 with **your exact board and firmware**.
  Published 2026-08-26, one commit, 10 stars.
- **[yath/tpm171e](https://github.com/yath/tpm171e)**: the original research the exploit comes from (65OLED873, same
  chip). One issue, "loader reboots TV", was fixed by a reset and a firmware update; no bricks reported there.
- **[XDA: Philips 2018 OLED873/12 root](https://xdaforums.com/t/philips-2018-oled873-12-root-succesfully.4563569/)**:
  all 64 posts, 2023 to 2024. Successes on a 65OLED873 and a 65PUS8602 (same firmware as yours). One brick.

## How it works

1. **Firmware:** download your firmware (1.3 GB) from the Toengel archive, decrypt it with a key file derived from
   `recovery-resource.dat` pulled off the TV, and take out `boot.img`.
2. **Patch:** run Magisk **v25.2** (newer versions boot-looped others) on the PC, in Docker, to patch `boot.img` with
   the 32-bit binaries.
3. **Root:** use a kernel exploit in Philips' own debug driver (`/dev/cli`, from yath) to get a temporary root
   shell. This needs no fastboot and no serial cable, only ADB, which you already have.
4. **Flash:** with that root shell, back up the boot partition, `dd` the patched image to `/boot` (`mmcblk0p5`),
   check the SHA-1 by reading it back, and reboot. Magisk then gives you permanent root.

## Where it goes wrong

| Risk | What happened | How likely for you |
|---|---|---|
| **Brick at the Philips logo** | The one brick on XDA (a PUS7363, a different 2018 model) used the **fastboot** route (`adb reboot bootloader`). He got stuck on the logo, the USB recovery did nothing, and he went looking for a new mainboard. yath warns: "Don't type `reboot bootloader`!" | **Low if fastboot is never used.** The saidsurucu method flashes with `dd` from the exploit shell and never enters fastboot. |
| **Boot loop after flashing** | orfin22's first attempt looped (fastboot route). He got out through a quick ADB window during boot. Wrong Magisk versions also looped. | **Low to medium.** Magisk 25.2 with the flags read from the device is what worked on your firmware. |
| **Recovery from a loop** | USB `upgrade_loader` for exactly 107.1.143.0 (2.15 GB, Toengel archive): a FAT32/MBR stick in the black USB port, about 25 minutes. It **reflashes everything, so it is a factory reset.** | It is the only safety net, and it can't be tested in advance without wiping the TV. It failed for the bricked PUS7363. |
| **Streaming apps stop working** | Nobody in any source tested this. Rooted devices can fail Google's Play Integrity, and some apps (Netflix, Disney+, banking) then refuse to install or play, or drop to SD. Widevine itself lives in the TV's secure chip and root doesn't erase it, but apps may refuse anyway. | **Unknown.** It is reversible, though: writing the stock boot image back removes root **without wiping**. |
| **Old, unmaintained root** | Magisk 25.2 is from 2022, and DenyList/Zygisk hiding on Android 8 TVs is untested. | Root hiding may or may not work. |

## What root would get you, compared with today

| You want | Without root (today) | With root |
|---|---|---|
| Your own Home screen | Already done | Same |
| Bloat out of sight | Hidden in the launcher | Truly removed, with a reliable way back |
| Tracking blocked | AdGuard DNS blocks the domains | Also stops `inscape_fp`, the screen-content daemon that runs without root |
| Know why the debloat boot-looped | Not possible (ADB is dead during a loop) | Kernel and boot logs survive and can be read afterwards |
| Newer Android or better speed | Not possible | **Still not possible:** closed drivers tie it to Android 8 |

The saidsurucu author's own conclusion: everything practical "was already possible without root", and "this project
is 'can it be done' curiosity; not a practical need." An external box (Google TV Streamer, Shield) is the sensible
upgrade, and Ambilight still works on HDMI input.

## If you decide to do it anyway

1. **Safety net first:** download and verify the 107.1.143.0 `upgrade_loader` (2.15 GB) and prepare the USB stick
   (8 GB or less, FAT32, MBR) before touching anything.
2. **Never use fastboot.** Only the exploit plus `dd` route, with the stock SHA-1 check and a full backup of the
   boot partition.
3. **Write your setup down first.** The launcher config is in git, and CLAUDE.md and TODO.md cover the rest. A
   recovery reflash means redoing Play and WebView, the apps and the logins (about an hour, as today showed).
4. **Test DRM straight after:** Netflix, Disney+, HBO Max, Viaplay and TV 2 Play. If they break and hiding doesn't
   help, `dd` the stock boot back to unroot without wiping.
5. **Tooling:** Docker on the PC (decryption and patching), Go (the exploit helper) and a Linux build of yath's
   `loader`. Roughly 3 to 5 hours the first time.

## If not

Carry on as now. The approved, low-risk tracker cleanup (four packages, one reboot each) is on hold until you
decide.
