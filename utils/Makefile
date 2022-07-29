include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling postinst

supersling_FILES = supersling.c
supersling_CODESIGN_FLAGS = -Sent.plist
supersling_INSTALL_PATH = $(INSTALL_PREFIX)/usr/libexec/zebra

postinst_FILES = postinst.m
postinst_CODESIGN_FLAGS = -Sent.plist
postinst_INSTALL_PATH = /DEBIAN

include $(THEOS_MAKE_PATH)/tool.mk
