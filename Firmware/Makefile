include $(THEOS)/makefiles/common.mk

TOOL_NAME = firmware

firmware_FILES = main.m DeviceInfo.m Firmware.m
firmware_FRAMEWORKS = CoreFoundation
firmware_CODESIGN_FLAGS = -Sent.plist
firmware_INSTALL_PATH = /usr/libexec/zebra

include $(THEOS_MAKE_PATH)/tool.mk
