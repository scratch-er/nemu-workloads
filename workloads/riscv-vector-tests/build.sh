#!/usr/bin/env bash
set -e

make -C "$SRC_DIR" RISCV_PREFIX="$CROSS_COMPILE" compile-stage1

mkdir -p "$PKG_DIR"/{bin,elf}
for file in "$SRC_DIR"/out/v256x64machine/bin/stage1-xs/* ; do
    case "$file" in
        *.bin)
            cp "$file" "$PKG_DIR"/bin/
            ;;
        *.txt)
            ;;
        *)
            cp "$file" "$PKG_DIR"/elf/
            ;;
    esac
done
