#!/usr/bin/env bash
set -e
set -x

CPIO_ARCHIVE="$1"
KERNEL_IMAGE="$2"
BUILD_DIR="$3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# prepare OpenSBI source
SBI_SOURCE="$SCRIPT_DIR/opensbi"
if [[ -e "$BUILD_DIR/opensbi" ]]; then
    rm -rf "$BUILD_DIR/opensbi"
fi
cp -r "$SBI_SOURCE" "$BUILD_DIR/opensbi"
cp "$SCRIPT_DIR/opensbi.config" "$BUILD_DIR/opensbi/platform/generic/configs/defconfig"

# Build device tree blob
sed -e "s/INITRAMFS_BEGIN/$INITRAMFS_BEGIN_HEX/g" \
    -e "s/INITRAMFS_END/$INITRAMFS_END_HEX/g" \
    "$SCRIPT_DIR/nemu.dts.in" > "$BUILD_DIR/nemu.dts"
dtc -I dts -O dtb -o "$BUILD_DIR/nemu.dtb" "$BUILD_DIR/nemu.dts"

# Build OpenSBI
cd "$BUILD_DIR/opensbi"
make PLATFORM=generic FW_PAYLOAD_OFFSET="$KERNEL_OFFSET_HEX" FW_FDT_PATH="$BUILD_DIR/nemu.dtb" FW_PAYLOAD_PATH="$KERNEL_IMAGE"

# Add initramfs to the image
cp "$BUILD_DIR/opensbi/build/platform/generic/firmware/fw_payload.bin" "$BUILD_DIR"
dd if="$CPIO_ARCHIVE" of="$BUILD_DIR/fw_payload.bin" bs="$MEGABYTE" seek="$INITRAMFS_OFFSET_MB" conv=notrunc
