NEMU_TRAP_VERSION = 0.0.1
NEMU_TRAP_SITE = $(BR2_EXTERNAL_NEMU_PATH)/package/nemu-trap
NEMU_TRAP_SITE_METHOD = local
NEMU_TRAP_INSTALL_STAGING = NO

define NEMU_TRAP_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(@D)/main.c -o $(@D)/nemu-trap
endef

define NEMU_TRAP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/nemu-trap $(TARGET_DIR)/bin
endef

define NEMU_TRAP_PERMISSIONS
	/bin/nemu-trap f 4755 root root - - - - -
endef

$(eval $(generic-package))
