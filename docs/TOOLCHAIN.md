# Toolchain and exact source provenance

Local clones used:

- yath/tpm171e: [`3c777a08ae0c85d780acaa8fad67cbc1b2bcbc63`](https://github.com/yath/tpm171e/tree/3c777a08ae0c85d780acaa8fad67cbc1b2bcbc63).
- saidsurucu/philips-tpm171e-root: [`a980969f4045ff19da7a19898fe7f39ad2196732`](https://github.com/saidsurucu/philips-tpm171e-root/tree/a980969f4045ff19da7a19898fe7f39ad2196732).

Recorded tools: xPack GNU Arm Embedded GCC 15.2.1-1.1 (Windows x64), Go 1.27.0 windows/amd64,
go-bindata v3.1.2+incompatible, Magisk 25.2. A different toolchain can change executable hashes.

I copied `getroot.c`, `getroot.lds`, `loader.go`, and `cli.go` from yath into a work directory and
`rootexec/main.go` from the reference into `rootexec_main.go`. In that directory, with the tools on PATH:

```sh
arm-none-eabi-gcc -W -Wall -Wextra -mcpu=cortex-a17 -mfpu=neon -Os -ffreestanding -nostdlib \
  -o getroot.elf -Wl,-r -T getroot.lds getroot.c
go-bindata -nocompress -pkg main -o assets.go getroot.elf
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -o loader loader.go assets.go
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -o rootexec rootexec_main.go
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -o cli cli.go
```

These commands use a POSIX shell (Git Bash works on Windows). The compiler target flags above are
the flags actually used, even though the identified SoC has Cortex-A53 cores. Output was ELF32 ARM,
statically linked. The Go `runtime.LockOSThread()` in rootexec is important: triggering the credentials
payload and executing the root command must happen on the same OS thread.

| Built/downloaded artifact | Bytes | Recorded SHA-1 |
|---|---:|---|
| getroot.elf | 1,732 | `1890b629ef80e9237f91a7a1c640d36f5f408752` |
| loader | 5,037,558 | `c5d1b8ced11bf39072432f5dca1cb5be89511b41` |
| rootexec | 2,312,369 | `a9523da2bf59b2b324c9c6889c4abb625c496866` |
| cli | 2,889,149 | `e3744dbb59761e3eee5822ab1c7fc436dce9eeae` |
| Magisk-v25.2.apk | 11,278,270 | `fffad3360f575b86e4bfeead8a93333d9009d08d` |

Original sources/binaries are obtained from upstream. They are not redistributed here. Upstream
licenses apply; linking a source does not relicense it under this repository's MIT license.

ADB was driven locally through cleanyourtv's Python `tv.py` helper, with `b64push.py` for larger
files that timed out through the plain pusher. Public guide commands use standard `adb` instead.
The private ADB key and helper virtualenv are not included. If using Git Bash for leading remote
paths, set `MSYS_NO_PATHCONV=1`; when pulling root-created files, make them readable first.
