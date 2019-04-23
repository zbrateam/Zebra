ARCHS = armv7 arm64 arm64e
TARGET = iphone::10.3:8.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling
supersling_FILES = main.c
supersling_INSTALL_PATH = /Applications/AUPM.app
supersling_CODESIGN_FLAGS = -Sent.plist

include $(THEOS_MAKE_PATH)/tool.mk
