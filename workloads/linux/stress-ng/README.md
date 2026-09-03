# stress-ng Linux workload

This workload statically cross-compiles stress-ng 0.18.05 for the Buildroot
RISC-V toolchain and packages it into a Linux initramfs image for NEMU.

The default run performs a bounded smoke test with one CPU worker, one VM
worker using 16 MiB, and one I/O worker. It uses per-stressor operation limits
instead of a wall-clock timeout. The workload keeps the guest timer enabled for
stress-ng worker scheduling, sends the profiling trap from `inittab`, and sends
the completion status from `run.sh`. The arguments can be changed at build
time with `STRESS_NG_ARGS`, for example:

```sh
make linux/stress-ng STRESS_NG_ARGS='--cpu 2 --cpu-ops 10000 --metrics-brief'
```

`stress-ng --help` lists all options. Common settings include `--cpu N`,
`--vm N`, and `--io N` to select workers; `--cpu-ops N`, `--vm-ops N`, and
`--io-ops N` to bound work; `--vm-bytes SIZE` to control VM allocation; and
`--metrics-brief`, `--verify`, or `--timeout T` for reporting, checking, or
time-based runs. Operation limits are preferred for short, reproducible NEMU
tests.

Build the image with:

```sh
make linux/stress-ng -jN
```
