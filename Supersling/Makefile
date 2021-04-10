ARCHS = x86_64
TARGET = macosx::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling
supersling_FILES = main.c
supersling_INSTALL_PATH = /opt/procursus/libexec/zebra
supersling_CODESIGN_FLAGS = -Sent.plist

after-stage::
	$(FAKEROOT) chmod 6755 $(THEOS_STAGING_DIR)/opt/procursus/libexec/zebra/supersling

include $(THEOS_MAKE_PATH)/tool.mk
