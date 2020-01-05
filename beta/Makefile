#!/bin/sh

all: Release
.PHONY: Packages Packages.xz Packages.bz2 Packages.gz Packages.lzma Release

Release: Packages Packages.xz Packages.bz2 Packages.gz Packages.lzma
	$(eval SIZE1 := $(shell wc -c Packages | awk '{print $$1}'))
	$(eval SIZE2 := $(shell wc -c Packages.xz | awk '{print $$1}'))
	$(eval SIZE3 := $(shell wc -c Packages.bz2 | awk '{print $$1}'))
	$(eval SIZE4 := $(shell wc -c Packages.gz | awk '{print $$1}'))
	$(eval SIZE5 := $(shell wc -c Packages.lzma | awk '{print $$1}'))
	@cp Release_ $@

	@echo SHA1: >> $@
	@echo " `shasum Packages | sed "s/  / $(SIZE1) /"`" >> $@
	@echo " `shasum Packages.xz | sed "s/  / $(SIZE2) /"`" >> $@
	@echo " `shasum Packages.bz2 | sed "s/  / $(SIZE3) /"`" >> $@
	@echo " `shasum Packages.gz | sed "s/  / $(SIZE4) /"`" >> $@
	@echo " `shasum Packages.lzma | sed "s/  / $(SIZE5) /"`" >> $@

	@echo SHA256: >> $@
	@echo " `shasum -a 256 Packages | sed "s/  / $(SIZE1) /"`" >> $@
	@echo " `shasum -a 256 Packages.xz | sed "s/  / $(SIZE2) /"`" >> $@
	@echo " `shasum -a 256 Packages.bz2 | sed "s/  / $(SIZE3) /"`" >> $@
	@echo " `shasum -a 256 Packages.gz | sed "s/  / $(SIZE4) /"`" >> $@
	@echo " `shasum -a 256 Packages.lzma | sed "s/  / $(SIZE5) /"`" >> $@

Packages:
	@dpkg-scanpackages -m . /dev/null > Packages

Packages.xz: Packages
	@xz -fk $^

Packages.bz2: Packages
	@bzip2 -fk $^

Packages.gz: Packages
	@gzip -fk $^

Packages.lzma: Packages
	@lzma -fk $^

clean:
	@rm -rf Packages Packages.xz Packages.bz2 Packages.gz Packages.lzma Release &> /dev/null
