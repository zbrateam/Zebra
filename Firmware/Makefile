ARCHS = arm64 arm64e
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = Firmware
Firmware_FILES = main.m DeviceInfo.m Firmware.m
Firmware_FRAMEWORKS = CoreFoundation
Firmware_CODESIGN_FLAGS = -Sent.plist
Firmware_INSTALL_PATH = /usr/libexec/zebra/firmware

# internal-stage::
# 	$(FAKEROOT) chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/zebra/firmware

include $(THEOS_MAKE_PATH)/tool.mk
