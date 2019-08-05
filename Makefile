include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/null.mk

all::
	xcodebuild CODE_SIGN_IDENTITY="" AD_HOC_CODE_SIGNING_ALLOWED=YES -quiet -scheme Zebra archive -archivePath Zebra.xcarchive PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"'

after-stage::
	mv Zebra.xcarchive/Products/Applications $(THEOS_STAGING_DIR)/Applications
	rm -rf Zebra.xcarchive
	$(MAKE) -C Supersling LEAN_AND_MEAN=1
	mkdir -p $(THEOS_STAGING_DIR)/usr/libexec/zebra
	mv $(THEOS_OBJ_DIR)/supersling $(THEOS_STAGING_DIR)/usr/libexec/zebra
	rm -rf $(THEOS_STAGING_DIR)/Applications/Zebra.app/embedded.mobileprovision
	ldid -S $(THEOS_STAGING_DIR)/Applications/Zebra.app/Zebra
	ldid -S $(THEOS_STAGING_DIR)/Applications/Zebra.app/Frameworks/SDWebImage.framework/SDWebImage
	ldid -SZebra/Zebra.entitlements $(THEOS_STAGING_DIR)/Applications/Zebra.app/Zebra

after-install::
	install.exec "killall \"Zebra\"" || true