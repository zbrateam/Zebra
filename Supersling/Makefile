# ARCHS = x86_64
# TARGET = macosx::11.0:11.0
ARCHS = arm64
TARGET = iphone::11.0:11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = supersling
supersling_FILES = main.c
supersling_INSTALL_PATH = /usr/libexec/$(LIBEXEC_FOLDER)
supersling_CODESIGN_FLAGS = -Sent.plist
supersling_CFLAGS = -DAPP_NAME=\"$(APP_NAME)\"

after-stage::	
	$(FAKEROOT) chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/$(LIBEXEC_FOLDER)/supersling

include $(THEOS_MAKE_PATH)/tool.mk
