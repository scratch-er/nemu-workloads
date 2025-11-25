# Device Tree Templates

This directory contains device tree templates for each device configuration. For each workload, device tree files are generated from the template on the fly, because some parameters cannot be known in advance.

## Parameters

These parameters are replaced with the corresponding values when building the workloads:

- `INITRAMFS_BEGIN`: Begin address of the initramfs containing the workload.
- `INITRAMFS_END`: End address of the initramfs containing the workload.

## Device Configurations

- `xiangshan.dts.in`: This device tree template is for the `riscv64-xs_defconfig` NEMU configuration.
- `yanqihu.dts.in`: This device tree template is for the `riscv64-yanqihu_defconfig` NEMU configuration.
