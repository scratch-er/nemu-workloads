#!/usr/bin/env bash
set -e

SBI_SOURCE_DIR="$(realpath "$1")"
SBI_BUILD_DIR="$(realpath "$2")"
BUILD_DIR="$(dirname "$SBI_BUILD_DIR")"

# prepare OpenSBI source
mkdir -p "$BUILD_DIR"
rm -rf "$SBI_BUILD_DIR"
cp -r "$SBI_SOURCE_DIR" "$SBI_BUILD_DIR"
cp "$SBI_SOURCE_DIR/../opensbi.config" "$SBI_BUILD_DIR/platform/generic/configs/defconfig"

# Build OpenSBI
cd "$SBI_BUILD_DIR"
patch -p1 < "$SBI_SOURCE_DIR/../opensbi.patch"
make PLATFORM=generic FW_JUMP=y FW_TEXT_START=0x80100000 FW_JUMP_ADDR=0x80200000 FW_JUMP_FDT_ADDR=0x80180000
