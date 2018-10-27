include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/null.mk

all::
	xcodebuild -scheme AUPM archive -archivePath AUPM.xcarchive

after-stage::
	mv AUPM.xcarchive/Products/Applications $(THEOS_STAGING_DIR)/Applications
	rm -rf AUPM.xcarchive
	$(MAKE) -C Supersling
	mv $(THEOS_OBJ_DIR)/supersling $(THEOS_STAGING_DIR)/Applications/AUPM.app/

after-install::
	install.exec "killall \"AUPM\"" || true
