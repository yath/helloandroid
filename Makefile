# location of the native development kit
NDK ?= /home/yath/android-dev/android-ndk-1.5_r1

# project (and executable) name
PROJECT ?= helloandroid

# where to put the executable on the phone
PDEST ?= /data

# path to adb (if not in $PATH)
ADB ?= adb

###################################################

# default target
all: $(PROJECT)

buildenv/apps/$(PROJECT)/Application.mk:
	mkdir -p $(dir $@)
	{ echo 'APP_PROJECT_PATH := $$(call my-dir)/project'; \
	  echo 'APP_MODULES      := $(PROJECT)'; \
	} > $@

buildenv/sources/$(PROJECT)/.stamp: $(CURDIR)/src/*
	mkdir -p $(dir $@)
	for i in $?; do ln -sf $$i $(dir $@); done
	touch $@

buildenv/%: $(NDK)/%
	mkdir -p $(dir $@)
	ln -sf $< $@

buildenv/.stamp: src/*
	mkdir -p $(dir $@)
	$(MAKE) buildenv/build buildenv/GNUmakefile buildenv/apps/$(PROJECT)/Application.mk buildenv/sources/$(PROJECT)/.stamp buildenv/out/host/config.mk
	touch $@

buildenv: buildenv/.stamp


.PHONY: clean
clean:
	rm -rf buildenv $(PROJECT) install-stamp


$(PROJECT): buildenv src/*
	make -C buildenv V=1 APP=$(PROJECT) $(MAKEFLAGS)
	@# XXX BIG FAT KLUDGE XXX
	@# this will fail if there is more than one binary with the same name
	@# XXX BIG FAT KLUDGE XXX
	find buildenv/apps/$(PROJECT)/project/libs -name $(PROJECT) -exec cp {} . \;

install-stamp: $(PROJECT)
	$(ADB) push $(PROJECT) $(PDEST)
	$(ADB) shell chmod 755 $(PDEST)
	touch $@

.PHONY: install
install: install-stamp

.PHONY: test
test: install
	@echo "======= BEGIN output of $(PROJECT) ======="
	@$(ADB) shell $(PDEST)/$(PROJECT)
	@echo "=======  END  output of $(PROJECT) ======="
