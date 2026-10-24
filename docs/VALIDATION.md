# Export validation

This repository was assembled on 2026-10-24 from the original local worklog and scripts.
All seven exported shell scripts passed `bash -n`; this was a syntax check, not execution.
No boot partition was read or written during repository preparation.

The main README reconciles historical intermediate states with the final installation: successful
Magisk flash/read-back, payload-free reboot with Enforcing SELinux, later Magisk environment repair,
and Netflix playback. Actual hardware results are from the original session, not a fresh root attempt.

The exported flash script is historical and intentionally exact-hash scoped. Its rollback limitations
are stated in README; syntax validation does not turn it into a general-purpose flashing tool.

Public files were checked for the original LAN address, headset/TV addresses, personal filesystem paths,
private-key headers and token-like strings. Boot images, private backups, ADB keys and vendor binaries
are excluded. Third-party attribution and the reference's retained MIT notice are included.
