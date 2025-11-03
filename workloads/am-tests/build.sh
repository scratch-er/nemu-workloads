#!/usr/bin/env bash
set -e

skip_tests=(aliastest bitmanip cachetest cacheoptest cputest crypto frequencytest memscantest softmdutest softprefetchtest)

mkdir -p "$PKG_DIR"/{bin,elf}
for test_dir in "$AM_HOME"/tests/* ; do
    if ! [[ "${skip_tests[@]}" =~ "$(basename "$test_dir")" ]]; then
        make -C "$test_dir" ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE"
        cp "$test_dir"/build/*.bin "$PKG_DIR"/bin/
        cp "$test_dir"/build/*.elf "$PKG_DIR"/elf/
    fi
done
