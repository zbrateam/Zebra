.PHONY: all
package:
	rm -rf Stage/AUPM.app
	xcodebuild -scheme AUPM archive -archivePath Stage/AUPM.xcarchive
	mv Stage/AUPM.xcarchive/Products/Applications/AUPM.app Stage/
	rm -rf Stage/AUPM.xcarchive
all:
	test -d "Stage" && package
