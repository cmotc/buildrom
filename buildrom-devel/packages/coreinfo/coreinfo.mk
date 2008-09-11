COREINFO_URL=svn://coreboot.org/repos/trunk/payloads/coreinfo
COREINFO_TAG=3561

COREINFO_DIR=$(BUILD_DIR)/coreinfo
COREINFO_SRC_DIR=$(COREINFO_DIR)/svn
COREINFO_STAMP_DIR=$(COREINFO_DIR)/stamps
COREINFO_LOG_DIR=$(COREINFO_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
COREINFO_FETCH_LOG=/dev/stdout
COREINFO_BUILD_LOG=/dev/stdout
else
COREINFO_BUILD_LOG=$(COREINFO_LOG_DIR)/build.log
COREINFO_FETCH_LOG=$(COREINFO_LOG_DIR)/fetch.log
endif

ifeq ($(CONFIG_COREBOOT_V3),y)
COREINFO_CONFIG=$(PACKAGE_DIR)/coreinfo/conf/defconfig-coreboot-v3
else
COREINFO_CONFIG=$(PACKAGE_DIR)/coreinfo/conf/defconfig-coreboot
endif

COREINFO_TARBALL=coreinfo-svn-$(COREINFO_TAG).tar.gz

$(SOURCE_DIR)/$(COREINFO_TARBALL):
	@ mkdir -p $(SOURCE_DIR)/coreinfo
	@ $(BIN_DIR)/fetchsvn.sh $(COREINFO_URL) $(SOURCE_DIR)/coreinfo \
	$(COREINFO_TAG) $(SOURCE_DIR)/$(COREINFO_TARBALL) \
	> $(COREINFO_FETCH_LOG) 2>&1

$(COREINFO_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(COREINFO_TARBALL) | $(COREINFO_STAMP_DIR) $(COREINFO_DIR)
	@ echo "Unpacking coreinfo..."
	@ tar -C $(COREINFO_DIR) -zxf $(SOURCE_DIR)/$(COREINFO_TARBALL)
	@ touch $@

$(COREINFO_SRC_DIR)/.config: $(COREINFO_STAMP_DIR)/.unpacked
	@ cp $(COREINFO_CONFIG) $@
	@ make -C $(COREINFO_SRC_DIR) oldconfig > $(COREINFO_BUILD_LOG) 2>&1

$(COREINFO_SRC_DIR)/build/coreinfo.elf: $(COREINFO_SRC_DIR)/.config
	@ echo "Building coreinfo..."
	@ make -C $(COREINFO_SRC_DIR) LIBPAYLOAD_DIR=$(STAGING_DIR)/libpayload \
	> $(COREINFO_BUILD_LOG) 2>&1

$(COREINFO_STAMP_DIR)/.copied: $(COREINFO_SRC_DIR)/build/coreinfo.elf
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(COREINFO_SRC_DIR)/build/coreinfo.elf $(PAYLOAD_ELF)
	@ touch $@

$(COREINFO_STAMP_DIR) $(COREINFO_LOG_DIR):
	@ mkdir -p $@

coreinfo: $(COREINFO_STAMP_DIR) $(COREINFO_LOG_DIR) $(COREINFO_STAMP_DIR)/.copied

coreinfo-clean:
	@ echo "Cleaning coreinfo..."
	@ rm -f $(COREINFO_STAMP_DIR)/.installed
	@ rm -f $(COREINFO_STAMP_DIR)/.copied
ifneq ($(wildcard $(COREINFO_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(COREINFO_SRC_DIR) clean > /dev/null 2>&1
endif

coreinfo-distclean:
	@ rm -rf $(COREINFO_DIR)/*

coreinfo-extract: $(COREINFO_STAMP_DIR)/.unpacked

coreinfo-config:
