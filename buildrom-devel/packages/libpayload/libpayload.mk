LIBPAYLOAD_URL=svn://coreboot.org/repos/trunk/payloads/libpayload
LIBPAYLOAD_TAG=3238

LIBPAYLOAD_DIR=$(BUILD_DIR)/libpayload
LIBPAYLOAD_SRC_DIR=$(LIBPAYLOAD_DIR)/svn
LIBPAYLOAD_STAMP_DIR=$(LIBPAYLOAD_DIR)/stamps
LIBPAYLOAD_LOG_DIR=$(LIBPAYLOAD_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
LIBPAYLOAD_FETCH_LOG=/dev/stdout
LIBPAYLOAD_BUILD_LOG=/dev/stdout
LIBPAYLOAD_INSTALL_LOG=/dev/stdout
else
LIBPAYLOAD_BUILD_LOG=$(LIBPAYLOAD_LOG_DIR)/build.log
LIBPAYLOAD_INSTALL_LOG=$(LIBPAYLOAD_LOG_DIR)/install.log
LIBPAYLOAD_FETCH_LOG=$(LIBPAYLOAD_LOG_DIR)/fetch.log
endif

ifeq ($(call custom-config-exists,libpayload), 1)
LIBPAYLOAD_CONFIG=$(call custom-config-name,libpayload)
else
ifeq ($(CONFIG_PLATFORM_GEODE),y)
LIBPAYLOAD_CONFIG=$(PACKAGE_DIR)/libpayload/conf/defconfig.geode
else
LIBPAYLOAD_CONFIG=$(PACKAGE_DIR)/libpayload/conf/defconfig
endif
endif

LIBPAYLOAD_TARBALL=libpayload-svn-$(LIBPAYLOAD_TAG).tar.gz

$(SOURCE_DIR)/$(LIBPAYLOAD_TARBALL):
	@ mkdir -p $(SOURCE_DIR)/libpayload
	@ $(BIN_DIR)/fetchsvn.sh $(LIBPAYLOAD_URL) $(SOURCE_DIR)/libpayload \
	$(LIBPAYLOAD_TAG) $(SOURCE_DIR)/$(LIBPAYLOAD_TARBALL) \
	> $(LIBPAYLOAD_FETCH_LOG) 2>&1

$(LIBPAYLOAD_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LIBPAYLOAD_TARBALL) | $(LIBPAYLOAD_STAMP_DIR) $(LIBPAYLOAD_DIR)
	@ echo "Unpacking libpayload..."
	@ tar -C $(LIBPAYLOAD_DIR) -zxf $(SOURCE_DIR)/$(LIBPAYLOAD_TARBALL)
	@ touch $@

$(LIBPAYLOAD_SRC_DIR)/.config: $(LIBPAYLOAD_STAMP_DIR)/.unpacked
	@ cp $(LIBPAYLOAD_CONFIG) $@
	@ make -C $(LIBPAYLOAD_SRC_DIR) oldconfig >  $(LIBPAYLOAD_BUILD_LOG) 2>&1

$(LIBPAYLOAD_SRC_DIR)/lib/libpayload.a: $(LIBPAYLOAD_SRC_DIR)/.config
	@ echo "Building libpayload..."
ifeq ($(findstring customconfig,$(LIBPAYLOAD_CONFIG)),customconfig)
	@ echo "Using custom config $(LIBPAYLOAD_CONFIG)"
endif
	@ make -C $(LIBPAYLOAD_SRC_DIR) > $(LIBPAYLOAD_BUILD_LOG) 2>&1
	@ mkdir -p $(OUTPUT_DIR)/config/libpayload
	@ cp $(LIBPAYLOAD_SRC_DIR)/.config $(OUTPUT_DIR)/config/libpayload

$(LIBPAYLOAD_STAMP_DIR)/.installed: $(LIBPAYLOAD_SRC_DIR)/lib/libpayload.a
	@ echo "Installing libpayload..."
	@ make -C $(LIBPAYLOAD_SRC_DIR) DESTDIR=$(STAGING_DIR) install \
	> $(LIBPAYLOAD_INSTALL_LOG) 2>&1
	@ touch $@

$(LIBPAYLOAD_STAMP_DIR) $(LIBPAYLOAD_LOG_DIR):
	@ mkdir -p $@

libpayload: $(LIBPAYLOAD_STAMP_DIR) $(LIBPAYLOAD_LOG_DIR) $(LIBPAYLOAD_STAMP_DIR)/.installed

libpayload-clean:
	@ echo "Cleaning libpayload..."
ifneq ($(wildcard "$(LIBPAYLOAD_SRC_DIR)/Makefile"),)
	@ $(MAKE) -C $(LIBPAYLOAD_SRC_DIR) clean > /dev/null 2>&1
endif
	@ rm -f $(LIBPAYLOAD_STAMP_DIR)/.installed

libpayload-distclean:
	@ rm -rf $(LIBPAYLOAD_DIR)/*

libpayload-extract: $(LIBPAYLOAD_STAMP_DIR)/.patched

libpayload-config: | $(LIBPAYLOAD_SRC_DIR)/.config
ifeq ($(call custom-config-exists,libpayload), 1)
	@ cp -f $(call custom-config-name,libpayload) $(LIBPAYLOAD_SRC_DIR)/.config
endif
	@ echo "Configure libpayload..."
	@ $(MAKE) -C $(LIBPAYLOAD_SRC_DIR) menuconfig
	@ echo
ifeq ($(call custom-config-exists,libpayload),1)
	@ echo "Found an existing custom configuration file:"
	@ echo "  $(call custom-config-name,libpayload)"
	@ echo "I've copied it back to the source directory for modification."
	@ echo "Remove the above file and re-run this command if you want to create a new customer configuration from scratch for this payload/board."
	@ echo
endif
	@ cp -f $(LIBPAYLOAD_SRC_DIR)/.config $(call custom-config-name,libpayload)
	@ echo "Your custom config file has been saved as $(call custom-config-name,libpayload)."
	@ echo

