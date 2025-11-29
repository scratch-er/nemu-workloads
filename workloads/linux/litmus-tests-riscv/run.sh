#!/bin/sh
cd /litmus-tests-riscv
set -x
set -e
./run.exe -st 1 -s 5k -r 20 | tee run.test.log

nemu-trap
