# This is the Generic coreboot target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(CBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

CBV2_PATCHES=$(PACKAGE_DIR)/coreboot-v2/patches/2761gxdk-fix-target.patch

CBV2_BASE_DIR=svn
CBV2_URL=svn://coreboot.org/repos/trunk/coreboot-v2
CBV2_TARBALL=coreboot-svn-$(CBV2_TAG).tar.gz
CBV2_PAYLOAD_TARGET=$(CBV2_BUILD_DIR)/payload.elf
TARGET_ROM = $(COREBOOT_VENDOR)-$(COREBOOT_BOARD).rom

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

# This matches the base name of the ROM on
# http://www.coreboot.org/data/optionroms/

OPTIONROM_ID = pci1039,6330
include $(PACKAGE_DIR)/coreboot-v2/optionroms.inc

$(SOURCE_DIR)/$(CBV2_TARBALL):
	@ echo "Fetching the coreboot code..."
	@ mkdir -p $(SOURCE_DIR)/coreboot
	@ $(BIN_DIR)/fetchsvn.sh $(CBV2_URL) $(SOURCE_DIR)/coreboot \
	$(CBV2_TAG) $(SOURCE_DIR)/$(CBV2_TARBALL) \
	> $(CBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(CBV2_OUTPUT) $(SOURCE_DIR)/$(OPTIONROM_ID).rom
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(SOURCE_DIR)/$(OPTIONROM_ID).rom $(CBV2_OUTPUT) > $@

coreboot: $(OUTPUT_DIR)/$(TARGET_ROM)
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
