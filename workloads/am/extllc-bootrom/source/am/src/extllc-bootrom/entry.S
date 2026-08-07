.section entry, "ax", @progbits
.globl _start
.type _start, @function

_start:
  .option push
  .option norvc
  .option norelax
  csrrsi x0, 0x744, 8
  addiw  t0, zero, 1
  slli   t1, t0, 42
  csrrc  x0, mstatus, t1
  .option pop

  csrr t0, mhartid
  bnez t0, .Lsecondary_park

  la sp, _stack_pointer
  tail _trm_init

.Lsecondary_park:
  wfi
  j .Lsecondary_park

.size _start, . - _start
