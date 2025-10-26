#!/usr/bin/env bash
set -e

BUILD_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SBI_BUILD_DIR="$BUILD_DIR/opensbi"
SBI_SOURCE="$SCRIPT_DIR/opensbi"

# prepare OpenSBI source
mkdir -p "$BUILD_DIR"
if [[ -e "$SBI_BUILD_DIR" ]]; then
    rm -rf "$SBI_BUILD_DIR"
fi
cp -r "$SBI_SOURCE" "$SBI_BUILD_DIR"
cp "$SCRIPT_DIR/opensbi.config" "$SBI_BUILD_DIR/platform/generic/configs/defconfig"

# Build OpenSBI
cd "$BUILD_DIR/opensbi"
make PLATFORM=generic FW_JUMP_ADDR=0x80200000
