#!/bin/sh
set -eu

if [ -r /etc/default/stress-ng ]; then
    . /etc/default/stress-ng
fi
STRESS_NG_ARGS="${STRESS_NG_ARGS:---cpu 1 --cpu-ops 1 --vm 1 --vm-ops 1 --vm-bytes 16M --io 1 --io-ops 1 --metrics-brief}"

echo "======== BEGIN stress-ng ========"
date -R || true
echo "CMD: /usr/bin/stress-ng ${STRESS_NG_ARGS}"
# The workload is intentionally configurable as a shell-style argument string,
# matching the other benchmark workloads in this repository.
set +e
/usr/bin/stress-ng ${STRESS_NG_ARGS}
status=$?
set -e
date -R || true
echo "======== END   stress-ng (status=${status}) ========"
nemu-trap "$status"
