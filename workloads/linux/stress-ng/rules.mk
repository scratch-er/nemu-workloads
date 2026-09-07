STRESS_NG_ARGS_HASH := $(shell printf '%s\n' "$(STRESS_NG_ARGS)" | sha256sum | cut -d ' ' -f 1)
STRESS_NG_ARGS_STAMP := build/linux-workloads/stress-ng/stress-ng-args.$(STRESS_NG_ARGS_HASH).stamp
STRESS_NG_BUILD_DIR := build/linux-workloads/stress-ng

# The generic Linux workload recipe invokes build.sh as a child process.
# Export the command line so that build.sh can record it in the guest image.
export STRESS_NG_ARGS

$(STRESS_NG_ARGS_STAMP):
	mkdir -p "$(@D)"
	rm -f "$(@D)"/stress-ng-args.*.stamp
	touch "$@"

$(eval $(call add_workload_linux,stress-ng))

# Rebuild the rootfs when the guest's stress-ng command line changes.
$(STRESS_NG_BUILD_DIR)/rootfs.cpio: $(STRESS_NG_ARGS_STAMP)
