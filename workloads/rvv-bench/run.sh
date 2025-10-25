#!/bin/sh
set -x

EXECS="memcpy memset memreverse utf8_count strlen mergelines mandelbrot chacha20 poly1305 ascii_to_utf16 ascii_to_utf32 byteswap LUT4 LUT6 hist base64_encode trans8x8e8 trans8x8e16"
for i in $EXECS; do
    if ! "/workloads/$i" ; then
        nemu-halt 1
    fi
done
nemu-halt
