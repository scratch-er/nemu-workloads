OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  FLASH (rxa) : ORIGIN = 0x10000000, LENGTH = 16M
  SRAM (rwxa) : ORIGIN = 0x37f00000, LENGTH = 32K
}

SECTIONS {
  .text : {
    KEEP(*(entry))
    *(.text) *(.text.*)
  } > FLASH

  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > FLASH

  .data : {
    sdata = .;
    *(.data) *(.data.*)
    *(.sdata) *(.sdata.*)
    edata = .;
  } > SRAM AT > FLASH
  _sidata = LOADADDR(.data);

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > SRAM AT > FLASH

  _stack_top = ALIGN(0x1000);
  . = _stack_top + 0x2000;
  _stack_pointer = .;
  _heap_start = _stack_pointer;
  _pmem_end = ORIGIN(SRAM) + LENGTH(SRAM);

  ASSERT(_stack_pointer <= ORIGIN(SRAM) + LENGTH(SRAM),
         "ExtLLC bootrom SRAM overflow")

  /DISCARD/ : {
    *(.eh_frame*)
    *(.comment*)
  }
}
