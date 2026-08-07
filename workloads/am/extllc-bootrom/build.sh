#!/usr/bin/env bash
set -euo pipefail

bootrom_arch="riscv64-xs-extllc-bootrom"

install -D \
    "$SRC_DIR/am/arch/$bootrom_arch.mk" \
    "$AM_HOME/am/arch/$bootrom_arch.mk"
install -D \
    "$SRC_DIR/am/include/arch/$bootrom_arch.h" \
    "$AM_HOME/am/include/arch/$bootrom_arch.h"
install -D \
    "$SRC_DIR/am/src/extllc-bootrom/entry.S" \
    "$AM_HOME/am/src/extllc-bootrom/entry.S"
install -D \
    "$SRC_DIR/am/src/extllc-bootrom/runtime.c" \
    "$AM_HOME/am/src/extllc-bootrom/runtime.c"
install -D \
    "$SRC_DIR/am/src/extllc-bootrom/bootrom.ld" \
    "$AM_HOME/am/src/extllc-bootrom/bootrom.ld"

mkdir -p "$PKG_DIR"/{bin,elf}

build_variant() {
    local variant="$1"
    local cppflags="$2"
    local artifact="$SRC_DIR/build/extllc-bootrom-$bootrom_arch"

    rm -rf "$SRC_DIR/build" "$AM_HOME/am/build" "$AM_HOME/libs/klib/build"
    make -C "$SRC_DIR" \
        ARCH="$bootrom_arch" \
        CROSS_COMPILE="$CROSS_COMPILE" \
        CPPFLAGS="$cppflags" \
        -j1

    cp "$artifact.bin" "$PKG_DIR/bin/extllc-bootrom-$variant.bin"
    cp "$artifact.elf" "$PKG_DIR/elf/extllc-bootrom-$variant.elf"
    cp "$artifact.map" "$PKG_DIR/elf/extllc-bootrom-$variant.map"
    cp "$artifact.txt" "$PKG_DIR/elf/extllc-bootrom-$variant.txt"
}

build_variant noprint ""
build_variant print "-DBOOTROM_PRINT=1 -DUART16550=1"
