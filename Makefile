# TODO: Remove when we advance to beta
ALPHA := 1

ALPHA ?= 0
BETA ?= 0

ifeq ($(PLATFORM), mac)
	export TARGET = uikitformac:latest:14.2
else
	export THEOS_PACKAGE_SCHEME = rootless
	export TARGET = iphone:latest:15.0
	export ARCHS = arm64
endif

ifeq ($(ALPHA), 1)
	PRODUCT_BUNDLE_IDENTIFIER = com.getzbra.zebra2
	export APP_NAME = "Zebra"
	export LIBEXEC_FOLDER = zebralpha
else ifeq ($(BETA), 1)
	PRODUCT_BUNDLE_IDENTIFIER = com.getzbra.zebra2
	export APP_NAME = "Zebra-Beta"
	export LIBEXEC_FOLDER = zebeta
else
	PRODUCT_BUNDLE_IDENTIFIER = com.getzbra.zebra2
	export APP_NAME = "Zebra"
	export LIBEXEC_FOLDER = zebra
endif

INSTALL_TARGET_PROCESSES = Zebra

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

Zebra_XCODEFLAGS = \
	PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' \
	PRODUCT_BUNDLE_IDENTIFIER=$(PRODUCT_BUNDLE_IDENTIFIER) \
	APP_NAME=$(APP_NAME) \
	LIBEXEC_FOLDER='@\"$(LIBEXEC_FOLDER)\"'
Zebra_CODESIGN_FLAGS = "-SZebra/Supporting Files/iOS.entitlements"

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = Supersling #Relaunch

# ifeq ($(ALPHA), 1)
# before-package::
# 	sed -Ei '' 's/^Name: Zebra/Name: Zebra [ALPHA]/g;s/^Package: (.*)$/Package: \1alpha/g' $(THEOS_STAGING_DIR)/DEBIAN/control
# else ifeq ($(BETA), 1)
# before-package::
# 	sed -Ei '' 's/^Name: Zebra/Name: Zebra [BETA]/g;s/^Package: (.*)$/Package: \1beta/g' $(THEOS_STAGING_DIR)/DEBIAN/control
# endif

after-stage::
	chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/$(LIBEXEC_FOLDER)/supersling
	$(ECHO_NOTHING)rm -f '$(THEOS_STAGING_DIR)/Applications/$(subst ",,$(APP_NAME)).app/Installed.pack'$(ECHO_END)

ifdef NO_LAUNCH
after-install::
	install.exec 'uicache -p /Applications/$(subst ",,$(APP_NAME)).app'
else
after-install::
	install.exec 'uicache -p /Applications/$(subst ",,$(APP_NAME)).app; uiopen zbra:'
endif

include $(THEOS_MAKE_PATH)/aggregate.mk
