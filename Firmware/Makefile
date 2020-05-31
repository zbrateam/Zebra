ARCHS = arm64 arm64e
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = firmware
firmware_FILES = main.m DeviceInfo.m Firmware.m
firmware_FRAMEWORKS = CoreFoundation
firmware_CODESIGN_FLAGS = -Sent.plist

include $(THEOS_MAKE_PATH)/tool.mk
