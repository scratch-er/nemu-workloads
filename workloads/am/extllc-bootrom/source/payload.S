.section .text.extllc_enter_payload, "ax", @progbits
.globl extllc_enter_payload
.type extllc_enter_payload, @function

extllc_enter_payload:
  fence iorw, iorw

  .option push
  .option norvc
  .option norelax
  addiw t0, zero, 1
  slli  t0, t0, 31
  jr    t0
  .option pop

.size extllc_enter_payload, . - extllc_enter_payload
