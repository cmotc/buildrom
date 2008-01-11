# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LBV2_BASE_DIR=svn
LBV2_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
LBV2_TARBALL=linuxbios-svn-$(LBV2_TAG).tar.gz
LBV2_PAYLOAD_TARGET=$(LBV2_BUILD_DIR)/payload.elf
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

# This is the list of components that comprise the ROM (excluding the payload)
LBV2_COMPONENTS = $(LBV2_OUTPUT)

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

# If an optionrom was specified in the configuration, then use it

ifneq ($(OPTIONROM_ID),)
include $(PACKAGE_DIR)/linuxbios/optionroms.inc

# Add it to the front of the list so it is prepended to the LinuxBIOS output
LBV2_COMPONENTS = $(SOURCE_DIR)/$(OPTIONROM_ID).rom $(LBV2_COMPONENTS)
endif

$(SOURCE_DIR)/$(LBV2_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LBV2_URL) $(SOURCE_DIR)/linuxbios \
	$(LBV2_TAG) $(SOURCE_DIR)/$(LBV2_TARBALL) \
	> $(LBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LBV2_COMPONENTS)
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(LBV2_COMPONENTS) > $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
