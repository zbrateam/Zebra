ifeq ($(ROOTLESS),1)
	export THEOS_PACKAGE_SCHEME = rootless
	export ARCHS = arm64
	export TARGET = iphone:latest:15.0
	export DEB_ARCH = iphoneos-arm64
	export IPHONEOS_DEPLOYMENT_TARGET = 15.0
	XCODE_SCHEME = Zebra - Rootless
else
	export ARCHS = armv7 arm64
	export TARGET = iphone:latest:9.0
	export DEB_ARCH = iphoneos-arm
	export IPHONEOS_DEPLOYMENT_TARGET = 9.0
	XCODE_SCHEME = Zebra - Legacy
endif

INSTALL_TARGET_PROCESSES = Zebra

export ADDITIONAL_CFLAGS = -DINSTALL_PREFIX='"$(THEOS_PACKAGE_INSTALL_PREFIX)"' \
	-DDEB_ARCH='"$(DEB_ARCH)"'

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

Zebra_XCODEFLAGS = MARKETING_VERSION=$(THEOS_PACKAGE_BASE_VERSION) \
	INSTALL_PREFIX=$(THEOS_PACKAGE_INSTALL_PREFIX) \
	DEB_ARCH=$(DEB_ARCH) \
	IPHONEOS_DEPLOYMENT_TARGET="$(IPHONEOS_DEPLOYMENT_TARGET)" \
	CODE_SIGN_IDENTITY="" \
	AD_HOC_CODE_SIGNING_ALLOWED=YES
Zebra_XCODE_SCHEME = $(XCODE_SCHEME)
Zebra_CODESIGN_FLAGS = -SZebra/Zebra.entitlements
Zebra_INSTALL_PATH = $(THEOS_PACKAGE_INSTALL_PREFIX)/Applications

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = utils

include $(THEOS_MAKE_PATH)/aggregate.mk

ipa:
	+$(MAKE) PACKAGE_FORMAT=ipa package

after-install::
	install.exec 'uiopen zbra:'
