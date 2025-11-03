#!/usr/bin/env bash
set -e
set -x

make -C "$SRC_DIR"/dtc CC="$CROSS_COMPILE"gcc LD="$CROSS_COMPILE"ld AR="$CROSS_COMPILE"ar NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 libfdt
make -C "$SRC_DIR"/kvmtool LIBFDT_DIR="$SRC_DIR"/dtc/libfdt ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" lkvm
"$CROSS_COMPILE"strip -s "$SRC_DIR"/kvmtool/lkvm

install -Dm 755 "$SRC_DIR"/kvmtool/lkvm "$PKG_DIR"/usr/bin/lkvm 
install -Dm 644 "$WORKLOAD_DIR"/inittab "$PKG_DIR"/etc/inittab
install -Dm 644 "$BUILDROOT_DIR"/output/images/Image "$PKG_DIR"/Image
