# Build the OpenFirmware payload

OFW_DIR=$(BUILD_DIR)/ofw
OFW_SRC_DIR=$(OFW_DIR)/svn
OFW_BUILD_DIR=$(OFW_SRC_DIR)/cpu/x86/pc/biosload/build
OFW_STAMP_DIR=$(OFW_DIR)/stamps
OFW_LOG_DIR=$(OFW_DIR)/logs

OFW_TARBALL=openfirmware-svn-$(OFW_SVN_TAG).tar.gz
#OFW_PATCHES=$(PACKAGE_DIR)/ofw/64bit-fix.patch
OFW_PATCHES=$(PACKAGE_DIR)/ofw/ofw_coreboot_qemu.patch

ifeq ($(CONFIG_VERBOSE),y)
OFW_FETCH_LOG=/dev/stdout
OFW_BUILD_LOG=/dev/stdout
OFW_INSTALL_LOG=/dev/stdout
else
OFW_FETCH_LOG=$(OFW_LOG_DIR)/fetch.log
OFW_BUILD_LOG=$(OFW_LOG_DIR)/build.log
OFW_INSTALL_LOG=$(OFW_LOG_DIR)/install.log
endif

# NOTE - this should be replaced by the GIT fetch or tarball fetch
# as appropriate

$(SOURCE_DIR)/$(OFW_TARBALL):
	@ echo "Fetching OpenFirmware..."
	@ echo "SVN Checkout rev $(OFW_SVN_TAG)"
	@ $(BIN_DIR)/fetchsvn.sh $(OFW_SVN_URL) $(SOURCE_DIR)/ofw \
	$(OFW_SVN_TAG) $@ > $(OFW_FETCH_LOG) 2>&1

$(OFW_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(OFW_TARBALL)
	@ echo "Unpacking OpenFirmware..."
	@ tar -C $(OFW_DIR) -zxf $(SOURCE_DIR)/$(OFW_TARBALL)
	@ touch $@	

$(OFW_STAMP_DIR)/.patched: $(OFW_STAMP_DIR)/.unpacked
	@ echo "Patching OpenFirmware..."
	@ $(BIN_DIR)/doquilt.sh $(OFW_SRC_DIR) $(OFW_PATCHES)
	@ touch $@

$(OFW_BUILD_DIR)/ofwlb.elf: $(OFW_STAMP_DIR)/.patched
	@ echo "Building OpenFirmware..."
	@ $(MAKE) -C $(OFW_BUILD_DIR) > $(OFW_BUILD_LOG) 2>&1

$(OFW_STAMP_DIR) $(OFW_LOG_DIR):
	@ mkdir -p $@

ofw: $(OFW_STAMP_DIR) $(OFW_LOG_DIR) $(OFW_BUILD_DIR)/ofwlb.elf 
	@ mkdir -p $(OUTPUT_DIR)
	@ install -m 0644 $(OFW_BUILD_DIR)/ofwlb.elf $(OUTPUT_DIR)/ofw-payload.elf

ofw-clean:
	@ echo "Cleaning Openfirmware..."
	@ $(MAKE) -C $(OFW_BUILD_DIR) clean > /dev/null 2>&1

ofw-distclean:
	@ rm -rf $(OFW_DIR)/*

