#!/usr/bin/env bash
set -e

tar -C "$SRC_DIR" -xf "$SRC_DIR/coremark.tar.gz"
make -C "$SRC_DIR/coremark-1.01" CC="$CROSS_COMPILE"gcc coremark.exe
install -Dm 755 "$SRC_DIR/coremark-1.01/coremark.exe" "$PKG_DIR/usr/bin/coremark"
install -Dm 644 "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc/inittab"
