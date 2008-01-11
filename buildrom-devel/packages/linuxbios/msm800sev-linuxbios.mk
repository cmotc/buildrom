# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LBV2_BASE_DIR=svn
LBV2_URL=svn://openbios.org/repos/trunk/LinuxBIOSv2
LBV2_TARBALL=linuxbios-svn-$(LBV2_TAG).tar.gz
LBV2_PAYLOAD_TARGET=$(LBV2_BUILD_DIR)/payload.elf
VSA_URL=http://www.amd.com/files/connectivitysolutions/geode/geode_lx/
LBV2_VSA=lx_vsa.36k.bin
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LBV2_VSA):
	@ echo "Fetching the VSA code..."
	wget -P $(SOURCE_DIR) $(VSA_URL)/$(LBV2_VSA).gz  -O $@

$(SOURCE_DIR)/$(LBV2_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LBV2_URL) $(SOURCE_DIR)/linuxbios \
	$(LBV2_TAG) $(SOURCE_DIR)/$(LBV2_TARBALL) \
	> $(LBV2_FETCH_LOG) 2>&1

# Special rule - append the VSA

$(OUTPUT_DIR)/$(TARGET_ROM): $(LBV2_OUTPUT) $(SOURCE_DIR)/$(LBV2_VSA)
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(SOURCE_DIR)/$(LBV2_VSA) $(LBV2_OUTPUT) > $@
	
linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
