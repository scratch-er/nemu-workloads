#!/usr/bin/env bash
set -e

build-test() {
    test_dir="$1"
    make -C "$test_dir" ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE"
    cp "$test_dir"/build/*.bin "$PKG_DIR"/bin/
    cp "$test_dir"/build/*.elf "$PKG_DIR"/elf/
}

skip_tests=(bitmanip cacheoptest cputest crypto frequencytest)
mkdir -p "$PKG_DIR"/{bin,elf}
for test_dir in "$AM_HOME"/tests/* ; do
    if ! [[ "${skip_tests[@]}" =~ "$(basename "$test_dir")" ]]; then
        build-test "$test_dir"
    fi
done

# `cputest` and `frequencytest` must be built after other tests are built,
# or ar would panic that "ar: am/build/am-riscv64-xs.a: malformed archive"
# I do not know why. But it only works this way
build-test "$AM_HOME"/tests/cputest
build-test "$AM_HOME"/tests/frequencytest

(
    set -e
    cd "$AM_HOME"/tests/bitmanip
    cd src
    find -iname '*.S' -exec rm -f {} +
    python3 randtest.py 10000 1
    cd ..
    make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE"
    mv build/bitmanip-riscv64-xs.bin "$PKG_DIR"/bin/bitmanip.bin
    mv build/bitmanip-riscv64-xs.elf "$PKG_DIR"/elf/bitmanip.elf
)

# `cacheoptest` must be built even after `bitmanip`,
# or ar would panic that "ar: am/build/am-riscv64-xs.a: malformed archive"
# I do not know why. But it only works this way
build-test "$AM_HOME"/tests/cacheoptest/icache
build-test "$AM_HOME"/tests/cacheoptest/dcache
build-test "$AM_HOME"/tests/cacheoptest/llc

# TODO: build `crypto`
cd "$AM_HOME"/tests/crypto
python src/randtest.py 1000 1 -o src/crypto
# `xperm.n` instruction is still not recognized
# make ARCH=riscv64-xs CROSS_COMPILE="$CROSS_COMPILE" ASFLAGS="-march=rv64gc_zknh_zknd_zkne_zksh_zba_zbb_zbc_zbs -Iinclude"
