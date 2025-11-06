#!/bin/sh
cd /coremark-pro/bin
set -x

for i in cjpeg-rose7-preset.exe loops-all-mid-10k-sp.exe parser-125k.exe sha-test.exe core.exe linear_alg-mid-100x100-sp.exe nnet_test.exe radix2-big-64k.exe zip-test.exe; do
    ./$i -c1 -w1 -v1 || nemu-trap $?
done

nemu-trap
