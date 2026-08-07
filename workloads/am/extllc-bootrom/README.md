# ExtLLC Bootrom

This AM workload builds the bootrom used to initialize the 2x2 ExtLLC and
enter the payload at `0x80000000`.

Build both variants with:

```sh
make am/extllc-bootrom
```

This target uses `riscv64-linux-gnu-` by default and does not require the
Buildroot Linux SDK. Override the prefix when needed:

```sh
make am/extllc-bootrom \
  EXTLLC_BOOTROM_CROSS_COMPILE=/path/to/bin/riscv64-linux-gnu-
```

The output package contains:

```text
build/am-workloads/extllc-bootrom/package/bin/extllc-bootrom-noprint.bin
build/am-workloads/extllc-bootrom/package/bin/extllc-bootrom-print.bin
build/am-workloads/extllc-bootrom/package/elf/extllc-bootrom-noprint.elf
build/am-workloads/extllc-bootrom/package/elf/extllc-bootrom-print.elf
```

The print variant initializes the UART16550 at `0x310b0000`. The noprint
variant does not initialize or access a UART.

Both variants execute in this order:

1. Set `mnstatus.nmie` and clear `mstatus.mdt`.
2. Park every hart except hart 0.
3. Use the 32 KiB SRAM at `0x37f00000` for data, BSS, and an 8 KiB stack.
4. Program the ExtLLC configuration registers.
5. Jump to `0x80000000`.

The first four instructions at the reset vector have the exact encodings
`0x74446073`, `0x0010029b`, `0x02a29313`, and `0x30033073`. After the
configuration writes, the final transfer uses `0x01f29293` and `0x00028067`.
The value in `t0` is reloaded before that transfer because the C initializer is
allowed to clobber caller-saved registers.

## Comparison with the no-SRAM diagnostic image

The historical no-SRAM image is a standalone assembly diagnostic. It embeds an
already compiled, stackless register sequence and adds flash checkpoints,
extra architectural-state initialization, and payload-state cleanup. This
workload intentionally does not carry those diagnostics. It uses the available
SRAM as an AM runtime stack and contains only the requested CSR setup, ExtLLC
register programming, optional UART output, and payload transfer.
