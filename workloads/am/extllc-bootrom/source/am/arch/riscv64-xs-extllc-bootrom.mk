MARCH ?= rv64gc_zicsr

include $(AM_HOME)/am/arch/isa/riscv64.mk

AM_SRCS := extllc-bootrom/runtime.c \
           extllc-bootrom/entry.S \
           noop/common/serial-16550.c

CFLAGS += -I$(AM_HOME)/am/src/nemu/include -DISA_H=\"riscv.h\"
LDFLAGS += -T $(AM_HOME)/am/src/extllc-bootrom/bootrom.ld

image:
	@echo + LD "->" $(BINARY_REL).elf
	@$(LD) $(LDFLAGS) --gc-sections -Map=$(BINARY).map \
		-o $(BINARY).elf --start-group $(LINK_FILES) --end-group
	@$(OBJDUMP) -d $(BINARY).elf > $(BINARY).txt
	@echo + OBJCOPY "->" $(BINARY_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents \
		-O binary $(BINARY).elf $(BINARY).bin
