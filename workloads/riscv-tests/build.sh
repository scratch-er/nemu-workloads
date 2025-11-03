#!/usr/bin/env bash
set -e

make -C "$SRC_DIR"/isa RISCV_PREFIX="$CROSS_COMPILE"

mkdir -p "$PKG_DIR"/{bin,elf}
for file in "$SRC_DIR"/isa/build/rv64* ; do
    case "$file" in
        *.bin)
            cp "$file" "$PKG_DIR"/bin/
            ;;
        *.dump)
            ;;
        *)
            cp "$file" "$PKG_DIR"/elf/
            ;;
    esac
done
