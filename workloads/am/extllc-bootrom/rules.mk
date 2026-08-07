EXTLLC_BOOTROM_BUILD_DIR := build/am-workloads/extllc-bootrom
EXTLLC_BOOTROM_DOWNLOAD_SENTINEL := $(EXTLLC_BOOTROM_BUILD_DIR)/download/sentinel
EXTLLC_BOOTROM_SENTINEL := $(EXTLLC_BOOTROM_BUILD_DIR)/sentinel
EXTLLC_BOOTROM_CROSS_COMPILE ?= riscv64-linux-gnu-
EXTLLC_BOOTROM_SOURCES := $(shell find \
	$(abspath workloads/am/extllc-bootrom) -type f)

$(EXTLLC_BOOTROM_DOWNLOAD_SENTINEL):
	mkdir -p "$(@D)"
	touch "$@"

$(EXTLLC_BOOTROM_SENTINEL): $(EXTLLC_BOOTROM_SOURCES) \
		scripts/build-workload-am.sh $(EXTLLC_BOOTROM_DOWNLOAD_SENTINEL)
	CROSS_COMPILE="$(EXTLLC_BOOTROM_CROSS_COMPILE)" \
		bash scripts/build-workload-am.sh \
		workloads/am/extllc-bootrom \
		$(EXTLLC_BOOTROM_BUILD_DIR) nexus-am

am/extllc-bootrom: $(EXTLLC_BOOTROM_SENTINEL)

WORKLOAD_PHONY_TARGETS += am/extllc-bootrom
WORKLOAD_DIRS += $(EXTLLC_BOOTROM_BUILD_DIR)
WORKLOADS_AM += $(EXTLLC_BOOTROM_BUILD_DIR)/package
WORKLOADS_AM_SENTINEL += $(EXTLLC_BOOTROM_SENTINEL)
TARFLAGS += --transform='s|^$(EXTLLC_BOOTROM_BUILD_DIR)/package|workloads/am/extllc-bootrom|'
