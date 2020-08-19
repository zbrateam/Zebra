ARCHS = arm64 arm64e
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling
supersling_FILES = main.c
supersling_INSTALL_PATH = /usr/libexec/zebra
supersling_CODESIGN_FLAGS = -Sent.plist

after-stage::
	$(FAKEROOT) chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/zebra/supersling

include $(THEOS_MAKE_PATH)/tool.mk
