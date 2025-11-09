#!/bin/sh
echo Hello, RISC-V from host!
cd /guest
echo Starting the guest.
lkvm run -m 64 -c1 --console serial -p 'console=ttyS0 earlycon=sbi' -i initramfs.cpio.zstd -k Image | sed 's/^/[guest]/'
nemu-trap $?
