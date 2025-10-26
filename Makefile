all: workloads

# Download buildroot
build/buildroot/Makefile:
	mkdir -p build
	wget https://buildroot.org/downloads/buildroot-2025.08.1.tar.gz -O build/buildroot.tar.gz
	tar -xf build/buildroot.tar.gz -C build
	mv build/buildroot-2025.08.1 build/buildroot

# Prepare buildroot SDK
build/buildroot/output/host/bin/toolchain-wrapper: $(shell find $(abspath br2-external)) build/buildroot/Makefile
	make -C build/buildroot BR2_EXTERNAL=$(abspath br2-external) nemu_defconfig
	make -C build/buildroot BR2_EXTERNAL=$(abspath br2-external) prepare-sdk

# Build Linux kernel
build/buildroot/output/images/Image: build/buildroot/output/host/bin/toolchain-wrapper
	make -C build/buildroot BR2_EXTERNAL=$(abspath br2-external) nemu_defconfig
	make -C build/buildroot BR2_EXTERNAL=$(abspath br2-external)

# Build OpenSBI
build/opensbi/build/platform/generic/firmware/fw_jump.bin: sbi/build-sbi.sh build/buildroot/output/host/bin/toolchain-wrapper
	CROSS_COMPILE="$(abspath build/buildroot/output/host/bin)/riscv64-linux-" \
	bash sbi/build-sbi.sh build

build/startup.bin: sbi/startup.s build/buildroot/output/host/bin/toolchain-wrapper
	$(abspath build/buildroot/output/host/bin)/riscv64-linux-as sbi/startup.s -o build/startup.o
	$(abspath build/buildroot/output/host/bin)/riscv64-linux-objcopy -O binary --only-section .text build/startup.o build/startup.bin

define add_workload
# Build and pack workload
build/$(1)/rootfs.cpio.zstd: $$(shell find $$(abspath workloads/$(1))) build/buildroot/output/host/bin/toolchain-wrapper
	CROSS_COMPILE="$$(abspath build/buildroot/output/host/bin)/riscv64-linux-" \
	SYSROOT_DIR="$$(abspath build/buildroot/output/staging)" \
	bash workloads/build-workload.sh workloads/$(1) build/$(1)

# Build all-in-one firmware
build/$(1)/fw_payload.bin: build/startup.bin sbi/nemu.dts.in sbi/build-sbi.sh sbi/build-firmware.sh build/$(1)/rootfs.cpio.zstd build/buildroot/output/images/Image build/opensbi/build/platform/generic/firmware/fw_jump.bin
	mkdir -p build/$(1)/
	CROSS_COMPILE="$$(abspath build/buildroot/output/host/bin)/riscv64-linux-" \
	DTC="$$(abspath build/buildroot/output/host/bin)/dtc" \
	bash sbi/build-firmware.sh build/startup.bin build/opensbi build/buildroot/output/images/Image build/$(1)

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

.PHONY: all workloads rootfs tarball clean-workloads
