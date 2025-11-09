all: workloads

# Download buildroot
BUILDROOT_DIR := build/buildroot
$(BUILDROOT_DIR)/Makefile:
	mkdir -p build
	wget https://buildroot.org/downloads/buildroot-2025.08.1.tar.gz -O build/buildroot.tar.gz
	tar -xf build/buildroot.tar.gz -C build
	mv build/buildroot-2025.08.1 $(BUILDROOT_DIR)

# Prepare buildroot SDK
TOOLCHAIN_WRAPPER := $(BUILDROOT_DIR)/output/host/bin/toolchain-wrapper
$(TOOLCHAIN_WRAPPER): br2-external/configs/nemu_defconfig $(BUILDROOT_DIR)/Makefile
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) nemu_defconfig
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) prepare-sdk

# Build Linux kernel
LINUX_IMAGE := $(BUILDROOT_DIR)/output/images/Image
$(LINUX_IMAGE): $(TOOLCHAIN_WRAPPER) br2-external/configs/nemu_defconfig br2-external/board/openxiangshan/nemu/linux.config
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) nemu_defconfig
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external)

# Build LibCheckpointAlpha
GCPT_BUILD_DIR := build/LibCheckpointAlpha
GCPT_BIN := $(GCPT_BUILD_DIR)/build/gcpt.bin
$(GCPT_BIN): scripts/build-gcpt.sh $(TOOLCHAIN_WRAPPER)
	CROSS_COMPILE="$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" bash scripts/build-gcpt.sh bootloader/LibCheckpointAlpha $(GCPT_BUILD_DIR)

# Build OpenSBI
SBI_BUILD_DIR := build/opensbi
SBI_BIN := $(SBI_BUILD_DIR)/build/platform/generic/firmware/fw_jump.bin
$(SBI_BIN): scripts/build-sbi.sh $(TOOLCHAIN_WRAPPER)
	CROSS_COMPILE="$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" bash scripts/build-sbi.sh bootloader/opensbi build/opensbi

define add_workload_linux
# Download files
build/$(1)/download/sentinel: $$(shell find $$(abspath workloads/$(1)) -iname 'links.txt')
	mkdir -p build/$(1)/
	bash scripts/download-files.sh workloads/$(1) build/$(1)/download

# Build and pack workload
build/$(1)/rootfs.cpio.zstd: $$(shell find $$(abspath workloads/$(1))) $(TOOLCHAIN_WRAPPER) build/$(1)/download/sentinel scripts/build-workload-linux.sh
	CROSS_COMPILE="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" \
	SYSROOT_DIR="$$(abspath $(BUILDROOT_DIR)/output/staging)" \
	BUILDROOT_DIR="$$(abspath $(BUILDROOT_DIR))" \
	bash scripts/build-workload-linux.sh workloads/$(1) build/$(1)

# Build all-in-one firmware
build/$(1)/fw_payload.bin: $(GCPT_BIN) dts/xiangshan.dts.in scripts/build-sbi.sh scripts/build-firmware-linux.sh build/$(1)/rootfs.cpio.zstd $(LINUX_IMAGE) build/opensbi/build/platform/generic/firmware/fw_jump.bin
	CROSS_COMPILE="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" \
	DTC="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/dtc" \
	bash scripts/build-firmware-linux.sh $(GCPT_BIN) build/opensbi dts/xiangshan.dts.in $(LINUX_IMAGE) build/$(1)

WORKLOAD_DIRS += build/$(1)
WORKLOADS_LINUX += build/$(1)/fw_payload.bin
ROOTFS += build/$(1)/rootfs.cpio.zstd
TARFLAGS += --transform='s|^build/$(1)|workloads/$(1)|'
endef

define add_workload_am
# Download files
build/$(1)/download/sentinel: $$(shell find $$(abspath workloads/$(1)) -iname 'links.txt')
	mkdir -p build/$(1)/
	bash scripts/download-files.sh workloads/$(1) build/$(1)/download

# Build and pack workload
build/$(1)/sentinel: $$(shell find $$(abspath workloads/$(1))) $(TOOLCHAIN_WRAPPER) build/$(1)/download/sentinel scripts/build-workload-am.sh
	CROSS_COMPILE="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" \
	SYSROOT_DIR="$$(abspath $(BUILDROOT_DIR)/output/staging)" \
	bash scripts/build-workload-am.sh workloads/$(1) build/$(1) nexus-am

WORKLOAD_DIRS += build/$(1)
WORKLOADS_AM += build/$(1)/package
WORKLOADS_AM_SENTINEL += build/$(1)/sentinel
TARFLAGS += --transform='s|^build/$(1)/package|workloads/$(1)|'
endef

# Define all workloads
$(eval $(call add_workload_linux,hello))
$(eval $(call add_workload_linux,rvv-bench))
$(eval $(call add_workload_linux,coremark))
$(eval $(call add_workload_linux,coremark-pro))
$(eval $(call add_workload_linux,kvmtool))
$(eval $(call add_workload_am,riscv-tests))
$(eval $(call add_workload_am,riscv-vector-tests))
$(eval $(call add_workload_am,am-tests-cputest))
$(eval $(call add_workload_am,am-tests-misc))

prepare-sdk: $(TOOLCHAIN_WRAPPER)

source: $(BUILDROOT_DIR)/Makefile
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) nemu_defconfig
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) source

# Build all all-in-one firmware images
workloads: $(WORKLOADS_LINUX) $(WORKLOADS_AM_SENTINEL)

# Build all rootfs
rootfs: $(ROOTFS)

# Pack all workloads
build/workloads.tar.zstd: $(WORKLOADS_LINUX) $(WORKLOADS_AM_SENTINEL)
	tar -c $(WORKLOADS_LINUX) $(ROOTFS) $(WORKLOADS_AM) $(TARFLAGS) | zstd -f -3 -T0 -o build/workloads.tar.zstd

# Pack images and rootfs
tarball: build/workloads.tar.zstd

# Remove all built workloads
clean-workloads:
	rm -rf $(WORKLOAD_DIRS) build/workloads.tar.zstd build/rootfs.tar.zstd

.PHONY: all prepare-sdk source workloads rootfs tarball clean-workloads
