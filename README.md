# NEMU Workload Builder

This repository serves as an automated build system to build the workloads of NEMU for testing purpose.

## Get Started

Simply run `make` under the repository. The Linux kernel, the workloads and the loadable images will be built automatically. The resulting files will end up in the `build` directory:

- `build/workload_name/fw_payload.bin`: The all-in-one image that can be directly loaded by NEMU.
- `build/workload_name/rootfs.cpio.zstd`: The initramfs overlay of the workload.

## Format of the Image

The image assumes that execution begins at `0x80000000`, and the image is loaded into a continuous memory starting from that address. The image contains the following content:

| Offset  | Content                       |
|---------|-------------------------------|
| 0       | startup code                  |
| 512 KiB | device tree                   |
| 1 MiB   | OpenSBI                       |
| 2 MiB   | Linux kernel                  |
| --      | initramfs containing workload |

The startup code is minimal, only loading the device tree address into register a1 and jumping to OpenSBI. This design may appear unnecessary. It could just put OpenSBI at the beginning. However, it enables key functionality for `libcheckpoint`. With this setup, you can replace the first 512 KiB of the image with `libcheckpoint`'s `gcpt.bin` or other custom code, reusing the existing OpenSBI and device tree. Furthermore, the entire first 1 MiB can be replaced by any custom code, as long as it correctly initializes a1 with a device tree address and passes control to OpenSBI.

The initramfs is placed after the Linux kernel and aligned to 1 MiB.

## How is the Linux Kernel Built

The linux kernel is built using buildroot. The `br2-external` subdirectory is a br2-external tree used for building the kernel. The kernel is built with a built-in initramfs containing:

- A musl dynamic C library
- BusyBox-based init and core utilities
- `/bin/nemu-halt` for stopping NEMU

When called without arguments, `/bin/nemu-halt` stops NEMU with exit code 0. When called with arguments, it stops NEMU using the exit code from the first argument, which must be a non-negative integer.

## How are the Workloads Built

Each workload becomes a binary file that NEMU loads directly. This file contains the device tree, OpenSBI, the Linux kernel, and the workload. Each sub-directory of `workload` is a "workload directory" defining how to build a workload. The build occurs in an ad hoc source directory, and the resulting files install into an ad hoc package directory. The package directory's content overlays the Linux kernel's built-in initramfs.

Each workload directory should contain:

- An optional `source` sub-directory, which should be a git submodule pointing to the workload's upstream repository or contain the workload's source code.
- An optional `links.txt` file with download links for files needed to build the workload, such as source tarballs or pre-built binaries. Each line in `links.txt` must follow the format: `file_name::link`, for example: `coremark.tar.gz::https://github.com/eembc/coremark/archive/refs/tags/v1.01.tar.gz`.
- A `build.sh` script that builds the workload. After `build.sh` exits normally, the package directory must contain everything needed to run the workload, including the executable, dependencies, and an `etc/inittab` that starts the workload and stops NEMU after it finishes.
- Any other necessary files, such as an `inittab` to start the workload, patches for building, or configuration files.

For each workload, the build system follows these steps:

1. Copies the workload directory's `source` sub-directory to a temporary location as the source directory for an off-tree build. If `source` does not exist, an empty directory is created. If the source directory already exists, it is deleted first.
2. If `links.txt` exists, downloads each file listed in it to the ad hoc source directory.
3. Creates the package directory. If the package directory already exists, it is deleted first.
4. Invokes the corresponding `build.sh` to build the workload and install it into the package directory.
5. Packs the package directory into an initramfs cpio archive.
6. Assembles the OpenSBI binary, Linux kernel, and initramfs (containing the workload) into a single binary file that NEMU loads directly.

Each `build.sh` script must access build information through these environment variables:

- `WORKLOAD_DIR`: the workload directory. The build script should not modify anything here.
- `SRC_DIR`: the ad hoc source directory. The build script can write to this directory.
- `PKG_DIR`: the ad hoc package directory. The build script can write to this directory.
- `CROSS_COMPILE`: the cross-compilation toolchain prefix, for example, `riscv64-linux-gnu-`.
- `SYSROOT_DIR`: the directory of the sysroot used for building the workload.

## Adding a Workload

You can add a workload with the following steps:

1. Add a workload subdirectory in `workloads` as stated above.
2. Add `$(eval $(call add_workload,workload_name))` in the Makefile.
