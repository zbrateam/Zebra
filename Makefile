ALPHA ?= 0
BETA ?= 0

ifeq ($(PLATFORM), mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:latest:11.0
export ARCHS = arm64
endif

ifeq ($(ALPHA), 1)
PRODUCT_BUNDLE_IDENTIFIER = xyz.willy.Zebralpha
export APP_NAME = "Zebra-Alpha"
export LIBEXEC_FOLDER = zebralpha
else ifeq ($(BETA), 1)
PRODUCT_BUNDLE_IDENTIFIER = xyz.willy.Zebeta
export APP_NAME = "Zebra-Beta"
export LIBEXEC_FOLDER = zebeta
else
PRODUCT_BUNDLE_IDENTIFIER = xyz.willy.Zebra
export APP_NAME = "Zebra"
export LIBEXEC_FOLDER = zebra
endif

INSTALL_TARGET_PROCESSES = Zebra

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

Zebra_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' PRODUCT_BUNDLE_IDENTIFIER=$(PRODUCT_BUNDLE_IDENTIFIER) APP_NAME=$(APP_NAME) LIBEXEC_FOLDER='@\"$(LIBEXEC_FOLDER)\"'
Zebra_CODESIGN_FLAGS = -SZebra/iOS.entitlements

include $(THEOS_MAKE_PATH)/xcodeproj.mk

PACKAGE_BUILDNAME :=
_THEOS_PACKAGE_DEFAULT_VERSION_FORMAT = $(THEOS_PACKAGE_BASE_VERSION)$(VERSION.EXTRAVERSION)

SUBPROJECTS = Supersling #Relaunch

ifeq ($(ALPHA), 1)
before-package::
	sed -i '' 's/^Name:.*/Name: Zebra (ALPHA)/g;s/^Package:.*/Package: xyz.willy.zebralpha/g' $(THEOS_STAGING_DIR)/DEBIAN/control
else ifeq ($(BETA), 1)
before-package::
	sed -i '' 's/^Name:.*/Name: Zebra (BETA)/g;s/^Package:.*/Package: xyz.willy.zebeta/g' $(THEOS_STAGING_DIR)/DEBIAN/control
endif

after-stage::
	chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/$(LIBEXEC_FOLDER)/supersling
	$(ECHO_NOTHING)mkdir -p '$(THEOS_STAGING_DIR)/Applications/$(subst ",,$(APP_NAME)).app/Sections'$(ECHO_END)
	$(ECHO_NOTHING)rm -f '$(THEOS_STAGING_DIR)/Applications/$(subst ",,$(APP_NAME)).app/Installed.pack'$(ECHO_END)

ifdef NO_LAUNCH
after-install::
	install.exec 'uicache -p /Applications/$(subst ",,$(APP_NAME)).app'
else
after-install::
	install.exec 'uicache -p /Applications/$(subst ",,$(APP_NAME)).app; uiopen zbra:'
endif

include $(THEOS_MAKE_PATH)/aggregate.mk
