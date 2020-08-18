ARCHS = arm64 arm64e
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = Supersling
Supersling_FILES = main.c
Supersling_INSTALL_PATH = /usr/libexec/zebra/supersling
Supersling_CODESIGN_FLAGS = -Sent.plist

# internal-stage::
# 	$(FAKEROOT) chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/zebra/supersling

include $(THEOS_MAKE_PATH)/tool.mk
