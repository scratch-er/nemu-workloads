#!/usr/bin/env bash
set -e

cp "$WORKLOAD_DIR/config.mk" "$SRC_DIR"
cp "$WORKLOAD_DIR/nolibc.h" "$SRC_DIR"
cp "$WORKLOAD_DIR/config.h" "$SRC_DIR/bench"
make -C "$SRC_DIR/bench"

EXECS="memcpy memset memreverse utf8_count strlen mergelines mandelbrot chacha20 poly1305 ascii_to_utf16 ascii_to_utf32 byteswap LUT4 LUT6 hist base64_encode trans8x8e8 trans8x8e16"
mkdir -p "$PKG_DIR/workloads"
for i in $EXECS; do
    install -m 755 "$SRC_DIR/bench/$i" "$PKG_DIR/workloads"
done
install -m 755 "$WORKLOAD_DIR/run.sh" "$PKG_DIR/workloads"

mkdir -p "$PKG_DIR/etc"
cp "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc"
