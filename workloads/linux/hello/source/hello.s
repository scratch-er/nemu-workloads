.data
msg:    .asciz "Hello, world!\n"
len = . - msg - 1

.text
.globl _start

_start:
    li a0, 1              # File descriptor: stdout = 1
    la a1, msg            # Load address of message string
    li a2, len            # Length of the string
    li a7, 64             # Linux syscall number for write (64)
    ecall                 # Make system call

    li a0, 0              # Exit status = 0
    .word 0x0000006b      # NEMU trap instruction
