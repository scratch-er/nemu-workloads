#!/usr/bin/env bash
set -euo pipefail

: "${CROSS_COMPILE:?CROSS_COMPILE is required}"

archive="$SRC_DIR/stress-ng-0.18.05.tar.gz"
source_dir="$SRC_DIR/stress-ng-0.18.05"

tar -C "$SRC_DIR" -xf "$archive"
make -C "$source_dir" \
    CC="${CROSS_COMPILE}gcc" \
    CXX="${CROSS_COMPILE}g++" \
    LD="${CROSS_COMPILE}gcc" \
    STATIC=1 \
    PRESERVE_CFLAGS=1 \
    -j"${JOBS:-$(nproc)}"

install -Dm755 "$source_dir/stress-ng" "$PKG_DIR/usr/bin/stress-ng"
install -Dm755 "$WORKLOAD_DIR/run.sh" "$PKG_DIR/stress-ng/run.sh"
install -Dm644 "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc/inittab"
install -d "$PKG_DIR/etc/default"
printf 'STRESS_NG_ARGS=%q\n' "${STRESS_NG_ARGS:---cpu 1 --cpu-ops 1 --vm 1 --vm-ops 1 --vm-bytes 16M --io 1 --io-ops 1 --metrics-brief}" > "$PKG_DIR/etc/default/stress-ng"
