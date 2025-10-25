#!/usr/bin/env bash
set -e
set -x

SBI_BUILD_DIR="$(realpath "$1")"
KERNEL_IMAGE="$(realpath "$2")"
WORKLOAD_BUILD_DIR="$(realpath "$3")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPIO_ARCHIVE="$WORKLOAD_BUILD_DIR/rootfs.cpio.zstd"
DTS_TEMPLATE="$SCRIPT_DIR/nemu.dts.in"

MEM_BEGIN=$(( 0x80000000 ))
KERNEL_OFFSET_MB=2

MEGABYTE=$(( 1024*1024 ))
KERNEL_OFFSET_HEX=$(printf "0x%x" $(( KERNEL_OFFSET_MB*MEGABYTE )))
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
dtc -I dts -O dtb -o "$WORKLOAD_BUILD_DIR/nemu.dtb" "$WORKLOAD_BUILD_DIR/nemu.dts"

# Build OpenSBI
rm -rf "$SBI_BUILD_DIR/build/platform/generic/firmware"
make -C "$SBI_BUILD_DIR" PLATFORM=generic FW_PAYLOAD_OFFSET="$KERNEL_OFFSET_HEX" FW_FDT_PATH="$WORKLOAD_BUILD_DIR/nemu.dtb" FW_PAYLOAD_PATH="$KERNEL_IMAGE"

# Add initramfs to the image
cp "$SBI_BUILD_DIR/build/platform/generic/firmware/fw_payload.bin" "$WORKLOAD_BUILD_DIR"
dd if="$CPIO_ARCHIVE" of="$WORKLOAD_BUILD_DIR/fw_payload.bin" bs="$MEGABYTE" seek="$INITRAMFS_OFFSET_MB" conv=notrunc
