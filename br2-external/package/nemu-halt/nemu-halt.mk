NEMU_HALT_VERSION = 0.0.1
NEMU_HALT_SITE = $(BR2_EXTERNAL_NEMU_PATH)/package/nemu-halt
NEMU_HALT_SITE_METHOD = local
NEMU_HALT_INSTALL_STAGING = NO

define NEMU_HALT_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(@D)/main.c -o $(@D)/nemu-halt
endef

define NEMU_HALT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/nemu-halt $(TARGET_DIR)/bin
endef

define NEMU_HALT_PERMISSIONS
	/bin/nemu-halt f 4755 root root - - - - -
endef

$(eval $(generic-package))
