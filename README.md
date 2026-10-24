# Root Philips TPM171E Android TV

How I rooted a **Philips 43PUS6412/12** running **TPM171E_R.107.001.143.000**, using temporary
root through the MediaTek debug driver, an on-device Magisk 25.2 boot patch, and a verified boot flash.
This is a record of an actual successful installation on 2026-10-24, not a universal Philips root tool.

**Result:** after a reboot without re-running the exploit, `su -c id` returned `uid=0(root)` with
`context=u:r:magisk:s0`, while SELinux was **Enforcing**. Netflix playback was subsequently tested working.
Other streaming apps and Play Integrity were not comprehensively tested.

The companion project, [BT-On-Philips-TV](https://github.com/mrk1987/BT-On-Philips-TV), explains how I
enabled Bluetooth audio, fixed pairing consent, and built a blue-button audio panel after rooting.

## Scope and precautions

Writing a boot partition can leave a TV unable to boot. A USB recovery package was prepared first;
its recovery procedure was documented but not exercised, because it reflashes the TV and erases setup.
I **did not use fastboot or `reboot bootloader`**. A serial console was not needed.
Do not assume another Philips TV, firmware, image length or partition number matches this one.
Keep the original boot backup off the TV before flashing. Do not flash this repository: it contains
documentation and scripts, not boot images. Generate a patch from your own verified stock boot image.

| Item | Tested value |
|---|---|
| Model / chassis | 43PUS6412/12 / TPM171E |
| Device / board | PH7M_EU_5596 / MediaTek MT5891 |
| Android / ABI | 8.0.0, SDK 26 / armeabi-v7a (32-bit) |
| Firmware | TPM171E_R.107.001.143.000, built 2021-11-08 |
| Boot partition | `/dev/block/mmcblk0p5`, 20,971,520 bytes |
| Debug interface | `/dev/cli`, accessible to the ADB shell |
| Root version | Magisk 25.2 |

## The procedure I actually used

### 1. Identify the device and prepare recovery

Enable USB debugging in Developer options, authorize your computer, and connect over ADB.
In commands below replace `TV_IP` with your TV's address; don't expose ADB to the internet.

```sh
adb connect TV_IP:5555
adb shell getprop ro.product.device
adb shell getprop ro.board.platform
adb shell getprop ro.tpvision.product.swversion
adb shell getprop ro.product.cpu.abilist
adb shell ls -l /dev/cli
```

I prepared a small FAT32/MBR USB stick with the exact firmware's `upgrade_loader.pkg`, from
[Toengel's firmware archive](https://toengel.net/philipsblog/firmware-archiv/). The archive and extracted
file were checked before flashing. Sizes/hashes and the recovery steps are in [Recovery](docs/RECOVERY.md).

### 2. Build the temporary-root tools

The exploit is original work by [yath/tpm171e](https://github.com/yath/tpm171e). The permanent-root
reference and thread-locked rootexec helper come from
[saidsurucu/philips-tpm171e-root](https://github.com/saidsurucu/philips-tpm171e-root).
I built their source locally; I did not use a downloaded patched boot image.

See [Toolchain and source revisions](docs/TOOLCHAIN.md) for the exact source commits, build commands,
and recorded tool hashes. The reference source explains the Go OS-thread locking needed to trigger
the exploit and exec the root command from the same thread.

Push the resulting ARM `loader` and `rootexec`:

```sh
adb push loader /data/local/tmp/loader
adb push rootexec /data/local/tmp/rootexec
adb shell chmod 755 /data/local/tmp/loader /data/local/tmp/rootexec
adb shell /data/local/tmp/loader -trigger=false
adb shell "/data/local/tmp/rootexec /system/bin/sh -c 'id; getenforce'"
```

On this exact TV the loader discovered `_CmdVersion=0xbf0bb87c`. That is an observation, not an
address to force on another unit. Temporary root showed uid 0 with the shell SELinux context and
Permissive mode. It lives in RAM: after every reboot the loader must run again before rootexec.

### 3. Back up the running boot partition

Run from the temporary-root shell:

```sh
dd if=/dev/block/mmcblk0p5 of=/data/local/tmp/boot-stock.img bs=4096 count=5120
sync
chmod 644 /data/local/tmp/boot-stock.img
sha1sum /data/local/tmp/boot-stock.img
```

Then pull it with `adb pull /data/local/tmp/boot-stock.img` and compare its hash on the PC.
The full partition backup was **20,971,520 bytes**, SHA-1
`4027c8a32d43832e05ab3e44ffc95bb091a9c2f0`.
The first **12,526,888 bytes** are the actual boot image; its hash was
`737cc3fff2e4e0885f39cdabd1418bb3ff62af74`, matching the upstream reference.
The image starts with `ANDROID!`. Full backups are private and excluded from this repository.

### 4. Patch on the TV with Magisk 25.2

Download [Magisk v25.2](https://github.com/topjohnwu/Magisk/releases/tag/v25.2).
Extract `assets/boot_patch.sh`, `assets/util_functions.sh`, and the ARMv7 libraries:
`libmagiskboot.so` -> `magiskboot`, `libmagiskinit.so` -> `magiskinit`,
`libmagisk32.so` -> `magisk32`. Stage them in `/data/local/tmp/magisk/` and mark binaries executable.
The APK is a ZIP archive. This TV has no 64-bit userspace; I used `armeabi-v7a` binaries only.

From the temporary-root shell:

```sh
dd if=/data/local/tmp/boot-stock.img of=/data/local/tmp/magisk/boot-stock-12m.img bs=12526888 count=1
cd /data/local/tmp/magisk
KEEPVERITY=false KEEPFORCEENCRYPT=false PATCHVBMETAFLAG=true RECOVERYMODE=false \
  sh boot_patch.sh /data/local/tmp/magisk/boot-stock-12m.img
```

These are the flags used on this firmware. The boot-patch script does not discover these flags by
calling `get_flags()` in this invocation. Inspect your own environment; do not generalize them to
encrypted devices or other models.

I first patched the complete 20 MB partition dump; the result had the wrong length/hash and was
**rejected without flashing**. Patching the exact 12,526,888-byte image produced:

| Check | Result |
|---|---|
| Patched size | 12,734,464 bytes |
| Patched SHA-1 | `5beaa29c84d3f583f911324a3d2b95505ad310ae` |
| Kernel SHA-1 | `1918b16aba2f51d45bf6b3934902999830922ce1`, unchanged |
| Ramdisk size | 8,021,982 bytes |
| `magiskboot cpio ramdisk.cpio test` | 1 (patched) |
| Reference comparison | byte-for-byte match |

The firmware-download/decryption/Docker approach in the upstream guide was **not** my actual route.
Dumping the running boot partition avoided that download and any firmware decryption keys.

### 5. Flash, read back, and only then reboot

I rechecked the backup, patched image and running stock image, then pushed and executed the
[historical flash script](scripts/flash-boot.sh) through rootexec. It checked boot magic, stock head
hash, patched size/hash, wrote the image, read back the written portion, and logged SUCCESS.
It did not reboot automatically.

```sh
adb push scripts/flash-boot.sh /data/local/tmp/flash-boot.sh
adb shell "/data/local/tmp/rootexec /system/bin/sh /data/local/tmp/flash-boot.sh"
adb shell cat /data/local/tmp/flash-boot.log
```

The observed write exited 0; read-back SHA-1 was `5beaa29c84d3f583f911324a3d2b95505ad310ae`.
Only after checking that result did I reboot. The script is the actual historical script, scoped to
these exact hashes: it is not a general-purpose flasher. In particular, it does not pre-validate the
rollback file and does not hash the restored partition if rollback runs. Independently verify the
backup before execution; a failed rollback must never be followed blindly by a reboot.

### 6. Grant the ADB shell Magisk access and verify another reboot

The first boot started Magisk but `su -c id` was denied for shell uid 2000. I ran the loader again,
then used temporary root to grant the shell policy:

```sh
/sbin/magisk --sqlite "INSERT OR REPLACE INTO policies (uid,policy,until,logging,notification) VALUES(2000,2,0,1,0);"
```

This grants persistent root access to authorized ADB shell sessions; it is not a password prompt.
I installed the full Magisk 25.2 APK over its stub, rebooted again without running the exploit, and checked:

```sh
adb shell "su -c id"
adb shell getenforce
```

Results: `uid=0(root) ... context=u:r:magisk:s0` and **Enforcing**.
That reboot established permanent root, rather than merely observing a live RAM exploit.

### 7. Repair the Magisk environment

Root worked, but `/data/adb/magisk` was empty. Magisk logged `Magisk environment incomplete, abort`;
boot-time script stages could not find BusyBox and silently failed. The earlier worklog's suggestion
that the empty directory needed no action was later corrected.

Extract from the same APK into `/data/local/tmp/magisk-env/`:
`libbusybox.so`, `libmagisk32.so`, `libmagiskinit.so`, `libmagiskboot.so`, `libmagiskpolicy.so`
(all from `lib/armeabi-v7a/`), plus the two asset scripts. Then run
[magisk-env-install.sh](scripts/magisk-env-install.sh) as root. It copies the files to `/data/adb/magisk`,
renames binaries and sets permissions. After reboot, the abort disappeared and boot script stages ran.

### 8. Backups and later root-dependent work

After rooting I backed up `system` (2 GiB), `user_setting`, `linux_rootfs`, `3rd_rw`, `perm`, and
selected `/data/data` + `/data/system` contents; hashes were compared on both sides. These backups
contain private data and are not published. `/data/app`, `/cache` and `/3rd` were not included.

I also installed a package-change boot guard, resized zram from 100 MB to 256 MB and stopped the
Inscape native service at boot. Sources and limitations are in [Post-root work](docs/POST-ROOT.md).
The larger original debloat list had caused boot loops and factory resets before this root work;
that list is not provided as a recommendation. Do not disable system-UID/persistent TV components.

## Rollback

With working root, restore **your own verified full stock backup**:

```sh
dd if=/data/local/tmp/boot-stock.img of=/dev/block/mmcblk0p5 bs=4096
sync
```

Check the command succeeded and hash the full read-back against the backup before rebooting.
This removes the patched boot without deliberately wiping data. This rollback path was prepared,
not executed on the completed installation. If Android cannot start, see [Recovery](docs/RECOVERY.md).
An OTA replacing boot can also remove root; revalidate rather than blindly reusing an old image.

## Records, credit and limits

- [Full sanitized session worklog](docs/ROOT-WORKLOG.md): both attempts, checksums, approvals and results.
- [Original pre-root assessment](docs/ROOT-ASSESSMENT.md): historical analysis; later results supersede it.
- [Sources and licensing](THIRD_PARTY.md): original exploit and reference procedure, pinned commits.
- [Bluetooth companion](https://github.com/mrk1987/BT-On-Philips-TV): profile enablement, pairing fix and panel.

No firmware, boot image, vendor library, ADB key, device-specific encryption key or private backup is
distributed. Root does not establish that a newer Android ROM or arbitrary firmware will work.
Only the exact hardware/firmware and checks stated above were tested.
