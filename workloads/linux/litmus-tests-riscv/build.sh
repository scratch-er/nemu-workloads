#!/usr/bin/env bash
set -e

unzip -q -d "$SRC_DIR" "$SRC_DIR/litmus-test-riscv-master.zip"
eval $(opam env)
make -C "$SRC_DIR/litmus-tests-riscv-master" hw-tests CORES=2 GCC=riscv64-unknown-linux-gnu-gcc -j8
cp -r "$SRC_DIR/litmus-tests-riscv-master/hw-tests" "$PKG_DIR/litmus-tests-riscv"
install -m 755 "$WORKLOAD_DIR/run.sh" "$PKG_DIR/litmus-tests-riscv/run-own.sh"
install -Dm 644 "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc/inittab"
