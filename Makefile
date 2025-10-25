all: payloads

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
build/opensbi/build/platform/generic/lib/libplatsbi.a: build/buildroot/output/host/bin/toolchain-wrapper
	CROSS_COMPILE="$(abspath build/buildroot/output/host/bin)/riscv64-linux-" \
	bash sbi/build-sbi.sh build

define add_workload
# Build and pack workload
build/$(1)/rootfs.cpio.zstd: $$(shell find $$(abspath workloads/$(1))) build/buildroot/output/host/bin/toolchain-wrapper
	CROSS_COMPILE="$$(abspath build/buildroot/output/host/bin)/riscv64-linux-" \
	SYSROOT_DIR="$$(abspath build/buildroot/output/staging)" \
	bash workloads/build-workload.sh workloads/$(1) build/$(1)

# Build all-in-one firmware
build/$(1)/fw_payload.bin: build/$(1)/rootfs.cpio.zstd build/buildroot/output/images/Image build/opensbi/build/platform/generic/lib/libplatsbi.a sbi/nemu.dts.in
	CROSS_COMPILE="$$(abspath build/buildroot/output/host/bin)/riscv64-linux-" \
	bash sbi/build-firmware.sh build/opensbi build/buildroot/output/images/Image build/$(1)

PAYLOADS += build/$(1)/fw_payload.bin
endef

$(eval $(call add_workload,hello))

payloads: $(PAYLOADS)

.NOTPARALLEL: $(PAYLOADS)
.PHONY: payloads
