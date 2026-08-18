#!/usr/bin/env bash
set -e

mkdir -p "$PKG_DIR"/{bin,elf}
make -C "$AM_HOME"/tests/rvh CROSS_COMPILE="$CROSS_COMPILE"
cp "$AM_HOME"/tests/rvh/build/*.bin "$PKG_DIR"/bin/
cp "$AM_HOME"/tests/rvh/build/*.elf "$PKG_DIR"/elf/
