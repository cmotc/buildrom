# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LBV2_PATCHES=$(PACKAGE_DIR)/linuxbios/patches/2761gxdk-fix-target.patch

LBV2_BASE_DIR=svn
LBV2_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
LBV2_TARBALL=linuxbios-svn-$(LBV2_TAG).tar.gz
LBV2_PAYLOAD_TARGET=$(LBV2_BUILD_DIR)/payload.elf
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

# This matches the base name of the ROM on
# http://www.linuxbios.org/data/optionroms/

OPTIONROM_ID = pci1039,6330
include $(PACKAGE_DIR)/linuxbios/optionroms.inc

$(SOURCE_DIR)/$(LBV2_TARBALL):
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LBV2_URL) $(SOURCE_DIR)/linuxbios \
	$(LBV2_TAG) $(SOURCE_DIR)/$(LBV2_TARBALL) \
	> $(LBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LBV2_OUTPUT) $(SOURCE_DIR)/$(OPTIONROM_ID).rom
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(SOURCE_DIR)/$(OPTIONROM_ID).rom $(LBV2_OUTPUT) > $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
