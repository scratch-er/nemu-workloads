#!/usr/bin/env bash
set -e

mkdir -p "$PKG_DIR"/{bin,elf}

cd "$AM_HOME"/apps/coremark

make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" clean
make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" CC_OPT="-O2 -march=rv64gc" -j1
cp build/coremark-riscv64-xs.bin "$PKG_DIR"/bin/coremark-riscv64-xs-rv64gc-o2.bin
cp build/coremark-riscv64-xs.elf "$PKG_DIR"/elf/coremark-riscv64-xs-rv64gc-o2.elf

make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" clean
make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" CC_OPT="-O3 -march=rv64gc" -j1
cp build/coremark-riscv64-xs.bin "$PKG_DIR"/bin/coremark-riscv64-xs-rv64gc-o3.bin
cp build/coremark-riscv64-xs.elf "$PKG_DIR"/elf/coremark-riscv64-xs-rv64gc-o3.elf

make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" clean
make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" CC_OPT="-O3 -march=rv64gcb" -j1
cp build/coremark-riscv64-xs.bin "$PKG_DIR"/bin/coremark-riscv64-xs-rv64gcb-o3.bin
cp build/coremark-riscv64-xs.elf "$PKG_DIR"/elf/coremark-riscv64-xs-rv64gcb-o3.elf
