ifeq ($(PLATFORM), mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:latest:11.0
export ARCHS = arm64
endif

INSTALL_TARGET_PROCESSES = Zebra

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

Zebra_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"'
Zebra_CODESIGN_FLAGS = -SZebra/iOS.entitlements

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = Supersling Firmware Relaunch

# firmware install path
export DESTDIR = $(THEOS_STAGING_DIR)/usr/libexec/zebra

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Applications/Zebra.app/Sections$(ECHO_END)
	$(ECHO_NOTHING)rm -f $(THEOS_STAGING_DIR)/Applications/Zebra.app/Installed.pack$(ECHO_END)

ifdef NO_LAUNCH
after-install::
	install.exec 'uicache -p /Applications/Zebra.app'
else
after-install::
	install.exec 'uicache -p /Applications/Zebra.app; uiopen zbra:'
endif

include $(THEOS_MAKE_PATH)/aggregate.mk
