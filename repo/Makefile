#!/bin/sh

all: Release
.PHONY: Packages Packages.bz2 Release

Release: Packages Packages.bz2
	$(eval SIZE1 := $(shell wc -c Packages | sed 's/[[:space:]].*//'))
	$(eval SIZE2 := $(shell wc -c Packages.bz2 | sed 's/[[:space:]].*//'))
	@cp Release_ $@

	@echo SHA1: >> $@
	@echo " `shasum Packages | sed "s/  / $(SIZE1) /"`" >> $@
	@echo " `shasum Packages.bz2 | sed "s/  / $(SIZE2) /"`" >> $@

	@echo SHA256: >> $@
	@echo " `shasum -a 256 Packages | sed "s/  / $(SIZE1) /"`" >> $@
	@echo " `shasum -a 256 Packages.bz2 | sed "s/  / $(SIZE2) /"`" >> $@

Packages:
	@dpkg-scanpackages -m . /dev/null > Packages

Packages.bz2: Packages
	@bzip2 -fk $^

clean:
	@rm -rf Packages Packages.bz2 Release &> /dev/null
