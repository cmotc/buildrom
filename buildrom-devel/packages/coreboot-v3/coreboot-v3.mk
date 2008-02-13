ifeq ($(CBV3_TAG),)
$(error You need to specify a version to pull in your platform config)
endif

CBV3_URL=svn://coreboot.org/repository/coreboot-v3
CBV3_TARBALL=coreboot-v3-svn-$(CBV3_TAG).tar.gz
CBV3_DIR=$(BUILD_DIR)/coreboot-v3
CBV3_SRC_DIR=$(CBV3_DIR)/svn

CBV3_STAMP_DIR=$(CBV3_DIR)/stamps
CBV3_LOG_DIR=$(CBV3_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
CBV3_FETCH_LOG=/dev/stdout
CBV3_CONFIG_LOG=/dev/stdout
CBV3_BUILD_LOG=/dev/stdout
else
CBV3_FETCH_LOG=$(CBV3_LOG_DIR)/fetch.log
CBV3_CONFIG_LOG=$(CBV3_LOG_DIR)/config.log
CBV3_BUILD_LOG=$(CBV3_LOG_DIR)/build.log
endif

TARGET_ROM = $(COREBOOT_VENDOR)-$(COREBOOT_BOARD).rom

CBV3_OUTPUT=$(CBV3_SRC_DIR)/build/coreboot.rom

CBV3_PATCHES ?=

$(SOURCE_DIR)/$(CBV3_TARBALL):
	@ mkdir -p $(SOURCE_DIR)/coreboot-v3
	@ $(BIN_DIR)/fetchsvn.sh $(CBV3_URL) \
	$(SOURCE_DIR)/coreboot-v3 $(CBV3_TAG) \
	$@ > $(CBV3_FETCH_LOG) 2>&1

$(CBV3_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(CBV3_TARBALL) | $(CBV3_STAMP_DIR)
	@echo "Unpacking coreboot v3..."
	@ mkdir -p $(CBV3_DIR)
	@ tar -C $(CBV3_DIR) -zxf $(SOURCE_DIR)/$(CBV3_TARBALL)
	@ touch $@

$(CBV3_STAMP_DIR)/.patched: $(CBV3_STAMP_DIR)/.unpacked
	@ echo "Patching coreboot v3..."
	@ $(BIN_DIR)/doquilt.sh $(CBV3_SRC_DIR) $(CBV3_PATCHES)
	@ touch $@

$(CBV3_STAMP_DIR)/.configured: $(CBV3_STAMP_DIR)/.patched
	@ echo "Configuring coreboot v3..."
ifeq ($(shell if [ -f $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ cp -f $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) $(CBV3_SRC_DIR)/.config
	@ echo "Using custom config $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)"
	@ make -C $(CBV3_SRC_DIR) oldconfig > $(CBV3_CONFIG_LOG) 2>&1
else
	@ make -C $(CBV3_SRC_DIR) defconfig \
		MAINBOARDDIR="$(COREBOOT_VENDOR)/$(COREBOOT_BOARD)" \
		> $(CBV3_CONFIG_LOG) 2>&1
endif
	@ touch $@

$(CBV3_OUTPUT): $(CBV3_STAMP_DIR)/.configured
	@ echo "Building coreboot v3..."
	@ $(MAKE) -C $(CBV3_SRC_DIR) > $(CBV3_BUILD_LOG) 2>&1

$(CBV3_SRC_DIR)/build/util/lar/lar: $(CBV3_STAMP_DIR)/.configured
	@ $(MAKE) -C $(CBV3_SRC_DIR)/util lar > $(CBV3_BUILD_LOG) 2>&1

$(STAGING_DIR)/bin/lar: $(CBV3_SRC_DIR)/build/util/lar/lar
	@ mkdir -p $(STAGING_DIR)/bin
	@ cp $< $@

$(CBV3_STAMP_DIR) $(CBV3_LOG_DIR):
	@ mkdir -p $@

coreboot-v3: $(CBV3_LOG_DIR) $(CBV3_STAMP_DIR) $(CBV3_OUTPUT) $(STAGING_DIR)/bin/lar

coreboot-v3-clean:
	@ echo "Cleaning coreboot v3..."
	@ $(MAKE) -C $(CBV3_SRC_DIR) clean > /dev/null 2>&1

coreboot-v3-distclean:
	@ rm -rf $(CBV3_DIR)/*
	@ rm -rf $(STAGING_DIR)/bin/lar

coreboot-v3-config: | $(CBV3_STAMP_DIR)/.configured
ifeq ($(shell if [ -f $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ cp -f $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) $(CBV3_SRC_DIR)/.config
endif
	@ echo "Configure coreboot-v3..."
	@ $(MAKE) -C $(CBV3_SRC_DIR) menuconfig
	@ echo
ifeq ($(shell if [ -f $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ echo "Found an existing custom configuration file:"
	@ echo "  $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)"
	@ echo "I've copied it back to the source directory for modification."
	@ echo "Remove the above file and re-run this command if you want to create a new custom configuration from scratch for this payload/board."
	@ echo
endif
	@ cp -f $(CBV3_SRC_DIR)/.config $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
	@ echo "Your custom coreboot-v3 config file has been saved as $(PACKAGE_DIR)/coreboot-v3/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)."
	@ echo
	@ touch $(CBV3_STAMP_DIR)/.configured
