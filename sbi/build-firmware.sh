#!/usr/bin/env bash
set -e

STARTUP_FILE="$(realpath "$1")"
SBI_BUILD_DIR="$(realpath "$2")"
KERNEL_IMAGE="$(realpath "$3")"
WORKLOAD_BUILD_DIR="$(realpath "$4")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPIO_ARCHIVE="$WORKLOAD_BUILD_DIR/rootfs.cpio.zstd"
DTS_TEMPLATE="$SCRIPT_DIR/nemu.dts.in"

MEM_BEGIN=$(( 0x80000000 ))
DTB_OFFSET_KB=512
SBI_OFFSET_KB=1024
KERNEL_OFFSET_MB=2

DTC="${DTC:-dtc}"

KILOBYTE=1024
MEGABYTE=$(( 1024*1024 ))
KERNEL_SIZE=$(stat -c%s "$KERNEL_IMAGE")
KERNEL_SIZE_MB=$(( (KERNEL_SIZE + MEGABYTE - 1) / MEGABYTE ))
INITRAMFS_OFFSET_MB=$(( KERNEL_OFFSET_MB + KERNEL_SIZE_MB ))
INITRAMFS_SIZE=$(stat -c%s "$CPIO_ARCHIVE")
INITRAMFS_BEGIN_HEX=$(printf "0x%x" $(( MEM_BEGIN + INITRAMFS_OFFSET_MB*MEGABYTE )))
INITRAMFS_END_HEX=$(printf "0x%x" $(( INITRAMFS_BEGIN_HEX + INITRAMFS_SIZE )))

# Build device tree blob
sed -e "s/INITRAMFS_BEGIN/$INITRAMFS_BEGIN_HEX/g" \
    -e "s/INITRAMFS_END/$INITRAMFS_END_HEX/g" \
    "$DTS_TEMPLATE" > "$WORKLOAD_BUILD_DIR/nemu.dts"
"$DTC" -I dts -O dtb -o "$WORKLOAD_BUILD_DIR/nemu.dtb" "$WORKLOAD_BUILD_DIR/nemu.dts"

# Assemble the image
dd if="$STARTUP_FILE" of="$WORKLOAD_BUILD_DIR/fw_payload.bin"
dd if="$WORKLOAD_BUILD_DIR/nemu.dtb" of="$WORKLOAD_BUILD_DIR/fw_payload.bin" bs="$KILOBYTE" seek="$DTB_OFFSET_KB" conv=notrunc
dd if="$SBI_BUILD_DIR/build/platform/generic/firmware/fw_jump.bin" of="$WORKLOAD_BUILD_DIR/fw_payload.bin" bs="$KILOBYTE" seek="$SBI_OFFSET_KB" conv=notrunc
dd if="$KERNEL_IMAGE" of="$WORKLOAD_BUILD_DIR/fw_payload.bin" bs="$MEGABYTE" seek="$KERNEL_OFFSET_MB" conv=notrunc
dd if="$CPIO_ARCHIVE" of="$WORKLOAD_BUILD_DIR/fw_payload.bin" bs="$MEGABYTE" seek="$INITRAMFS_OFFSET_MB" conv=notrunc
