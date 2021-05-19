BETA ?= 0

ifeq ($(PLATFORM), mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:latest:11.0
export ARCHS = arm64
endif

ifneq ($(BETA),0)
PRODUCT_BUNDLE_IDENTIFIER = xyz.willy.Zebeta
BUNDLE_IDENTIFIER = xyz.willy.zebeta
export APP_NAME = "Zebra-Beta"
NAME = Zebra (BETA)
export LIBEXEC_FOLDER = zebeta
else
PRODUCT_BUNDLE_IDENTIFIER = xyz.willy.Zebra
BUNDLE_IDENTIFIER = xyz.willy.zebra
export APP_NAME = "Zebra"
NAME = Zebra
export LIBEXEC_FOLDER = zebra
endif

INSTALL_TARGET_PROCESSES = Zebra

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Zebra

Zebra_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' PRODUCT_BUNDLE_IDENTIFIER=$(PRODUCT_BUNDLE_IDENTIFIER) APP_NAME=$(APP_NAME) LIBEXEC_FOLDER='@\"$(LIBEXEC_FOLDER)\"'
Zebra_CODESIGN_FLAGS = -SZebra/iOS.entitlements

before-stage::
	$(ECHO_NOTHING)cp -rf zebra.control control$(ECHO_END)
	$(ECHO_NOTHING)echo -e 'Package: $(BUNDLE_IDENTIFIER)\nName: $(NAME)' >> control$(ECHO_END)

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = Supersling #Relaunch

clean::
	$(ECHO_NOTHING)rm -f control$(ECHO_END)

after-stage::
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
