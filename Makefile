ifeq ($(PLATFORM), mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:latest:11.0
export ARCHS = armv7 arm64
endif

INSTALL_TARGET_PROCESSES = Zebra

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

Zebra_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"'
Zebra_CODESIGN_FLAGS = -SZebra/Zebra.entitlements

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = Supersling

after-all::
	@$(PRINT_FORMAT_MAKING) "Making all in Firmware"
	@cd Firmware && $(MAKE) all

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Applications/Zebra.app/Sections$(ECHO_END)
	$(ECHO_NOTHING)rm -f $(THEOS_STAGING_DIR)/Applications/Zebra.app/Installed.pack$(ECHO_END)

	@$(PRINT_FORMAT_MAKING) "Making install in Firmware"
	@cd Firmware && $(MAKE) install DESTDIR=$(THEOS_STAGING_DIR)/usr/libexec/zebra

after-install::
	install.exec 'uicache -p /Applications/Zebra.app; uiopen zbra:'

after-clean::
	@$(PRINT_FORMAT_MAKING) "Making clean in Firmware"
	$(ECHO_CLEANING)cd Firmware && $(MAKE) clean$(ECHO_END)

include $(THEOS_MAKE_PATH)/aggregate.mk