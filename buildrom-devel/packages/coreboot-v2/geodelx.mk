# This target supports all Geode LX platforms
#
ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(CBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

CBV2_BASE_DIR=svn
CBV2_URL=svn://coreboot.org/repos/trunk/coreboot-v2
CBV2_TARBALL=coreboot-svn-$(CBV2_TAG).tar.gz
CBV2_PAYLOAD_TARGET=$(CBV2_BUILD_DIR)/payload.$(CBV2_PAYLOAD_FILE_EXT)

TARGET_ROM = $(COREBOOT_VENDOR)-$(COREBOOT_BOARD).rom

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

$(SOURCE_DIR)/$(CBV2_TARBALL):
	@ echo "Fetching the coreboot rev $(CBV2_TAG) code..."
	@ mkdir -p $(SOURCE_DIR)/coreboot
	@ $(BIN_DIR)/fetchsvn.sh $(CBV2_URL) $(SOURCE_DIR)/coreboot \
	$(CBV2_TAG) $(SOURCE_DIR)/$(CBV2_TARBALL) \
	> $(CBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(CBV2_OUTPUT) $(GEODE_PADDED_VSA)
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(GEODE_PADDED_VSA) $(CBV2_OUTPUT) > $@

coreboot: geodevsa $(OUTPUT_DIR)/$(TARGET_ROM)
coreboot-clean: geodevsa-clean generic-coreboot-clean
coreboot-distclean: geodevsa-distclean generic-coreboot-distclean
