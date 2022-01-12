export ARCHS = armv7 arm64
export TARGET = iphone::10.3:9.0

INSTALL_TARGET_PROCESSES = Zebra

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

# CLANG_WARN_STRICT_PROTOTYPES=NO required to ignore a warning treated as error from LNPopupController
Zebra_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' \
	CODE_SIGN_IDENTITY="" AD_HOC_CODE_SIGNING_ALLOWED=YES \
	CLANG_WARN_STRICT_PROTOTYPES=NO
Zebra_CODESIGN_FLAGS = -SZebra/Zebra.entitlements

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = Supersling Firmware

include $(THEOS_MAKE_PATH)/aggregate.mk

ipa:
	+$(MAKE) PACKAGE_FORMAT=ipa package

after-install::
	install.exec 'uiopen zbra:'
