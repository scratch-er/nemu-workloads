#!/usr/bin/env bash
set -e

tar -C "$SRC_DIR" -xf "$SRC_DIR/coremark-pro.tar.gz"
make -C "$SRC_DIR/coremark-pro-1.1.2743" CC="$CROSS_COMPILE"gcc LD="$CROSS_COMPILE"gcc build
cp -r "$SRC_DIR/coremark-pro-1.1.2743/builds/linux64/gcc64" "$PKG_DIR/coremark-pro"
install -m 755 "$WORKLOAD_DIR/run.sh" "$PKG_DIR/coremark-pro/run.sh"
install -Dm 644 "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc/inittab"
