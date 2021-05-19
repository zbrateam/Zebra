ARCHS = arm64
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = relaunch
relaunch_FILES = main.c
relaunch_INSTALL_PATH = /usr/libexec/$(LIBEXEC_FOLDER)
relaunch_CODESIGN_FLAGS = -Sent.plist

after-stage::
	$(FAKEROOT) chmod 755 $(THEOS_STAGING_DIR)/usr/libexec/$(LIBEXEC_FOLDER)/relaunch

include $(THEOS_MAKE_PATH)/tool.mk
