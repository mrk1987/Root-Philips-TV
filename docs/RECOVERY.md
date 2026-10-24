# Recovery prepared before flashing

The exact firmware's `upgrade_loader` was obtained from
[Toengel's archive](https://toengel.net/philipsblog/firmware-archiv/), row TPM171E_107.001.143.000.
The ZIP CRC check passed; the extracted file was copied to the root of a 4 GB-class FAT32/MBR USB stick.

| Artifact | Bytes | SHA-1 recorded |
|---|---:|---|
| TPM171E_107.1.143.0_upgrade_loader.zip | 2,154,113,926 | `638e2a5faca47c4287ba856afaf9fe0863cc6e09` |
| upgrade_loader.pkg | 2,183,351,736 | `a0717aa7cfb8ef4ea153a7bbcfb30e34243c8abb` |

The checksum identifies the file used in this experiment. Obtain packages from their original source;
this repository does not distribute them or provide a guarantee for another TV.

The reference procedure, **not exercised on this installation**, was:

1. Unplug the TV and disconnect other cables, including CI/CAM.
2. Put the stick in the black USB port, not the blue port.
3. Connect power; wait for automatic recovery, or use remote power if it does not start.
4. Allow around 25 minutes, then remove the stick and factory-reset the TV as directed by the reference.

This is a full firmware recovery/factory reset, not a guaranteed no-wipe rollback. Having a prepared
stick is not proof that recovery will work after every kind of failure. Never use fastboot as a
substitute for the tested ADB/temporary-root procedure.
