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

define add_workload
# Download files
build/$(1)/download/sentinel: $$(shell find $$(abspath workloads/$(1)) -iname 'links.txt')
	mkdir -p build/$(1)/
	bash scripts/download-files.sh workloads/$(1) build/$(1)/download

# Build and pack workload
build/$(1)/rootfs.cpio.zstd: $$(shell find $$(abspath workloads/$(1))) $(TOOLCHAIN_WRAPPER) build/$(1)/download/sentinel
	CROSS_COMPILE="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" \
	SYSROOT_DIR="$$(abspath $(BUILDROOT_DIR)/output/staging)" \
	bash scripts/build-workload.sh workloads/$(1) build/$(1)

# Build all-in-one firmware
build/$(1)/fw_payload.bin: $(GCPT_BIN) dts/xiangshan.dts.in scripts/build-sbi.sh scripts/build-firmware.sh build/$(1)/rootfs.cpio.zstd $(LINUX_IMAGE) build/opensbi/build/platform/generic/firmware/fw_jump.bin
	CROSS_COMPILE="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/riscv64-linux-" \
	DTC="$$(abspath $(BUILDROOT_DIR)/output/host/bin)/dtc" \
	bash scripts/build-firmware.sh $(GCPT_BIN) build/opensbi dts/xiangshan.dts.in $(LINUX_IMAGE) build/$(1)

WORKLOAD_DIRS += build/$(1)
WORKLOADS += build/$(1)/fw_payload.bin
ROOTFS += build/$(1)/rootfs.cpio.zstd
TAR_FLAG_WORKLOADS += --transform='s|build/$(1)/fw_payload.bin|fw_payload_$(1).bin|'
TAR_FLAG_ROOTFS += --transform='s|build/$(1)/rootfs.cpio.zstd|rootfs_$(1).cpio.zstd|'
endef

# Define all workloads
$(eval $(call add_workload,hello))
$(eval $(call add_workload,rvv-bench))
$(eval $(call add_workload,coremark))
$(eval $(call add_workload,coremark-pro))

prepare-sdk: $(TOOLCHAIN_WRAPPER)

source: $(BUILDROOT_DIR)/Makefile
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) nemu_defconfig
	make -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(abspath br2-external) source

# Build all all-in-one firmware images
workloads: $(WORKLOADS)

# Build all rootfs
rootfs: $(ROOTFS)

# Pack all images
build/workloads.tar.zstd: $(WORKLOADS)
	tar -c $(WORKLOADS) $(TAR_FLAG_WORKLOADS) | zstd -f -3 -T0 -o build/workloads.tar.zstd

# Pack all rootfs
build/rootfs.tar.zstd: $(ROOTFS)
	tar -c $(ROOTFS) $(TAR_FLAG_ROOTFS) | zstd -f -3 -T0 -o build/rootfs.tar.zstd

# Pack images and rootfs
tarball: build/workloads.tar.zstd build/rootfs.tar.zstd

# Remove all built workloads
clean-workloads:
	rm -rf $(WORKLOAD_DIRS) build/workloads.tar.zstd build/rootfs.tar.zstd

.PHONY: all prepare-sdk source workloads rootfs tarball clean-workloads
