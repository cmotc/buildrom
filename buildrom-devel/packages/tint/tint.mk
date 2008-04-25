TINT_ORIG_URL=http://ftp.debian.org/debian/pool/main/t/tint/
TINT_TARBALL=tint_0.03b.tar.gz
TINT_PATCH_REV=3239
TINT_PATCH_URL="http://tracker.coreboot.org/trac/coreboot/browser/trunk/payloads/external/tint/libpayload_tint.patch?rev=$(TINT_PATCH_REV)&format=raw"
TINT_PATCH=libpayload_tint.patch

TINT_DIR=$(BUILD_DIR)/tint
TINT_SRC_DIR=$(TINT_DIR)/tint-0.03b
TINT_STAMP_DIR=$(TINT_DIR)/stamps
TINT_LOG_DIR=$(TINT_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
TINT_BUILD_LOG=/dev/stdout
else
TINT_BUILD_LOG=$(TINT_LOG_DIR)/build.log
endif

$(SOURCE_DIR)/$(TINT_TARBALL):
	@ wget --quiet -P $(SOURCE_DIR) -O $@ $(TINT_ORIG_URL)/$(TINT_TARBALL)

$(SOURCE_DIR)/$(TINT_PATCH):
	@ wget --quiet -P $(SOURCE_DIR) -O $@ $(TINT_PATCH_URL)

$(TINT_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(TINT_TARBALL) | $(TINT_DIR)
	@ tar -C $(TINT_DIR) -zxf $(SOURCE_DIR)/$(TINT_TARBALL)
	@ mkdir -p $(TINT_STAMP_DIR)
	@ touch $@

$(TINT_STAMP_DIR)/.patched: $(SOURCE_DIR)/$(TINT_PATCH) $(TINT_STAMP_DIR)/.unpacked
	@ cat $(SOURCE_DIR)/$(TINT_PATCH) | patch -d $(TINT_SRC_DIR) -p1
	@ touch $@

$(TINT_SRC_DIR)/tint.elf: $(TINT_STAMP_DIR)/.patched | $(TINT_LOG_DIR)
	@ echo "Building TINT..."
	@ make -C $(TINT_SRC_DIR)  LIBPAYLOAD_DIR=$(STAGING_DIR)/libpayload > $(TINT_BUILD_LOG) 2>&1

$(TINT_STAMP_DIR)/.copied: $(TINT_SRC_DIR)/tint.elf
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(TINT_SRC_DIR)/tint.elf $(PAYLOAD_ELF)
	@ touch $@

$(TINT_DIR) $(TINT_LOG_DIR):
	@ mkdir -p $@

tint: $(TINT_STAMP_DIR)/.copied

tint-clean:
	@ echo "Cleaning TINT..."
ifneq ($(wildcard $(TINT_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(TINT_SRC_DIR) clean
endif
	@ rm -f $(TINT_STAMP_DIR)/.copied

tint-distclean:
	@ rm -rf $(TINT_DIR)
