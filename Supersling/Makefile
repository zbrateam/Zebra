ARCHS = arm64 arm64e
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling
supersling_FILES = main.c
supersling_CODESIGN_FLAGS = -Sent.plist

include $(THEOS_MAKE_PATH)/tool.mk
