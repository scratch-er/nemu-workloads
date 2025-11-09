#!/usr/bin/env bash
set -e
set -x

make -C "$SRC_DIR"/dtc CC="$CROSS_COMPILE"gcc LD="$CROSS_COMPILE"ld AR="$CROSS_COMPILE"ar NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 libfdt
make -C "$SRC_DIR"/kvmtool LIBFDT_DIR="$SRC_DIR"/dtc/libfdt ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" lkvm
"$CROSS_COMPILE"strip -s "$SRC_DIR"/kvmtool/lkvm

(
    cd "$SRC_DIR"/guest
    find . | cpio -H newc -o | zstd -o ../initramfs.cpio.zstd
)

install -Dm 755 "$SRC_DIR"/kvmtool/lkvm "$PKG_DIR"/usr/bin/lkvm 
install -Dm 644 "$WORKLOAD_DIR"/inittab "$PKG_DIR"/etc/inittab
install -Dm 755 "$WORKLOAD_DIR"/run.sh "$PKG_DIR"/guest/run.sh
install -Dm 644 "$BUILDROOT_DIR"/output/images/Image "$PKG_DIR"/guest/Image
install -Dm 644 "$SRC_DIR"/initramfs.cpio.zstd "$PKG_DIR"/guest/initramfs.cpio.zstd
