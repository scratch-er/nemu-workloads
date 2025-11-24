#!/usr/bin/env bash
set -e

mkdir -p "$PKG_DIR"/{bin,elf}
make -C "$AM_HOME"/apps/hello ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" -j1
cp "$AM_HOME"/apps/hello/build/*.bin "$PKG_DIR"/bin/
cp "$AM_HOME"/apps/hello/build/*.elf "$PKG_DIR"/elf/
