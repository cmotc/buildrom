# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LINUXBIOS_BASE_DIR=svn
LINUXBIOS_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
LINUXBIOS_TARBALL=linuxbios-svn-$(LINUXBIOS_TAG).tar.gz
LINUXBIOS_PAYLOAD_TARGET=$(LINUXBIOS_BUILD_DIR)/payload.elf
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

# This is the list of components that comprise the ROM (excluding the payload)
LINUXBIOS_COMPONENTS = $(LINUXBIOS_OUTPUT)

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

# If an optionrom was specified in the configuration, then use it

ifneq($(OPTIONROM_ID),)
include $(PACKAGE_DIR)/linuxbios/optionroms.inc

# Add it to the front of the list so it is prepended to the LinuxBIOS output
LINUXBIOS_COMPONENTS = $(SOURCE_DIR)/$(OPTIONROM_ID).rom $(LINUXBIOS_COMPONENTS)
endif

$(SOURCE_DIR)/$(LINUXBIOS_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LINUXBIOS_URL) $(SOURCE_DIR)/linuxbios \
	$(LINUXBIOS_TAG) $(SOURCE_DIR)/$(LINUXBIOS_TARBALL) \
	> $(LINUXBIOS_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LINUXBIOS_COMPONENTS)
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(LINUXBIOS_COMPONENTS) > $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
