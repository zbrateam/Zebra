include $(THEOS)/makefiles/common.mk

# Supersling and postinst aren’t needed for rootless builds.
ifneq ($(THEOS_PACKAGE_SCHEME),rootless)
TOOL_NAME += supersling postinst

supersling_FILES = supersling.c
supersling_CODESIGN_FLAGS = -Sent.plist
supersling_INSTALL_PATH = $(INSTALL_PREFIX)/Applications/Zebra.app

postinst_FILES = postinst.m
postinst_CODESIGN_FLAGS = -Sent.plist
postinst_INSTALL_PATH = /DEBIAN
endif

include $(THEOS_MAKE_PATH)/tool.mk
