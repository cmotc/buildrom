# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LINUXBIOS_BASE_DIR=svn
LINUXBIOS_URL=svn://openbios.org/repos/trunk/LinuxBIOSv2
LINUXBIOS_TARBALL=linuxbios-svn-$(LINUXBIOS_TAG).tar.gz
LINUXBIOS_PAYLOAD_TARGET=$(LINUXBIOS_BUILD_DIR)/payload.elf
VSA_URL=http://www.amd.com/files/connectivitysolutions/geode/geode_lx/
LINUXBIOS_VSA=lx_vsa.36k.bin
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LINUXBIOS_VSA):
	@ echo "Fetching the VSA code..."
	wget -P $(SOURCE_DIR) $(VSA_URL)/$(LINUXBIOS_VSA).gz  -O $@

$(SOURCE_DIR)/$(LINUXBIOS_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LINUXBIOS_URL) $(SOURCE_DIR)/linuxbios \
	$(LINUXBIOS_TAG) $(SOURCE_DIR)/$(LINUXBIOS_TARBALL) \
	> $(LINUXBIOS_FETCH_LOG) 2>&1

# Special rule - append the VSA

$(OUTPUT_DIR)/$(TARGET_ROM): $(LINUXBIOS_OUTPUT) $(SOURCE_DIR)/$(LINUXBIOS_VSA)
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(SOURCE_DIR)/$(LINUXBIOS_VSA) $(LINUXBIOS_OUTPUT) > $@
	
linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
