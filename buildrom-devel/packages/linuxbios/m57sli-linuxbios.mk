# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LBV2_PATCHES= 

ifeq ($(CONFIG_PAYLOAD_FILO),y)
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/m57sli-filo-and-etherboot-Config.lb.patch
endif

ifeq ($(CONFIG_PAYLOAD_ETHERBOOT),y)
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/m57sli-filo-and-etherboot-Config.lb.patch
endif

ifeq ($(CONFIG_PAYLOAD_KERNEL),y)
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/m57sli-kernel-and-lab-Config.lb.patch
endif

ifeq ($(CONFIG_PAYLOAD_LAB),y)
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/m57sli-kernel-and-lab-Config.lb.patch
endif


LBV2_BASE_DIR=svn
LBV2_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
LBV2_TARBALL=linuxbios-svn-$(LBV2_TAG).tar.gz
LBV2_PAYLOAD_TARGET=$(LBV2_BUILD_DIR)/payload.elf
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LBV2_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LBV2_URL) $(SOURCE_DIR)/linuxbios \
	$(LBV2_TAG) $(SOURCE_DIR)/$(LBV2_TARBALL) \
	> $(LBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LBV2_OUTPUT)
	@ mkdir -p $(OUTPUT_DIR)
	@ cat $(LBV2_OUTPUT) > $@
	
linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
