#!/usr/bin/env bash
set -e

make -C "$SRC_DIR" RISCV_PREFIX="$CROSS_COMPILE" compile-stage1

# Only these workloads are in the NEMU CI workloads on the self hosted runner.
# Only include them to be consistant with the original CI flow.
include_tests=(
    vfadd.vf-0.bin
    vfsgnj.vv-0.bin
    vfsub.vf-0.bin
    vle16.v-0.bin
    vle32.v-0.bin
    vlse32.v-0.bin
    vlseg4e32.v-0.bin
    vlsseg4e32.v-0.bin
    vluxei32.v-0.bin
    vor.vi-0.bin
    vse16.v-0.bin
    vsetivli-0.bin
    vsetvl-0.bin
    vsetvli-0.bin
    vslide1down.vx-0.bin
    vsse16.v-1.bin
    vsuxei32.v-0.bin
)

mkdir -p "$PKG_DIR"/{bin,elf}
for file in "$SRC_DIR"/out/v256x64machine/bin/stage1-xs/* ; do
    case "$file" in
        *.bin)
            if [[ " ${include_tests[@]} " =~ " $(basename $file) " ]]; then
                cp "$file" "$PKG_DIR"/bin/
            fi
            ;;
        *.txt)
            ;;
        *)
            cp "$file" "$PKG_DIR"/elf/
            ;;
    esac
done
