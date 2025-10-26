# address of the dtb
li a1,0x80080000
# address of OpenSBI
li t0,0x80100000
# launch OpenSBI
jalr zero, t0
