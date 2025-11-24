#!/usr/bin/env bash
set -e

build-test() {
    test_dir="$1"
    make -C "$test_dir" ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" -j1
    cp "$test_dir"/build/*.bin "$PKG_DIR"/bin/
    cp "$test_dir"/build/*.elf "$PKG_DIR"/elf/
}

mkdir -p "$PKG_DIR"/{bin,elf}
build-test "$AM_HOME"/tests/cputest
