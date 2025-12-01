#!/usr/bin/env bash
set -e

tar -C "$SRC_DIR" -xzf "$SRC_DIR/litmus-tests-riscv-2C.tar.gz"
cp -r "$SRC_DIR/litmus-tests-riscv-2C" "$PKG_DIR/litmus-tests-riscv"
install -m 755 "$WORKLOAD_DIR/run.sh" "$PKG_DIR/litmus-tests-riscv/run-simple.sh"
install -Dm 644 "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc/inittab"
