.PHONY: all
package:
	mkdir -p .stage
	rm -rf .stage/Applications/AUPM.app
	mkdir -p .stage/Applications
	xcodebuild -scheme AUPM archive -archivePath .stage/AUPM.xcarchive
	mv .stage/AUPM.xcarchive/Products/Applications/AUPM.app .stage/Applications/
	rm -rf .stage/AUPM.xcarchive
	cd Supersling && make
	mv Supersling/.theos/obj/debug/supersling .stage/Applications/AUPM.app/
	cp -r layout/* .stage/
	mkdir -p .stage/DEBIAN
	cp control .stage/DEBIAN/
	cp postinst .stage/DEBIAN/
	chmod -R 755 .stage/DEBIAN/
	cd .stage && find . -name '.DS_Store' -type f -delete
	$(THEOS)/bin/dm.pl .stage xyz.willy.aupm.deb
	rm -rf .stage
	tar -czf - xyz.willy.aupm.deb | ssh -p 2222 root@localhost  'tar -xzf  -  -C  /tmp/'
	ssh root@localhost -p 2222 'apt-get remove xyz.willy.aupm -y --force-yes'
	ssh root@localhost -p 2222 'dpkg -i /var/root/xyz.willy.aupm.deb'
	ssh root@localhost -p 2222 'rm -rf /var/root/xyz.willy.aupm.deb'
	ssh root@localhost -p 2222 'killall AUPM'
all:
	test -d ".stage" && package
