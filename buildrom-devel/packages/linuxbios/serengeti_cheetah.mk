# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LBV2_PATCHES =

# Make sure we have the tools we need to accomplish this
HAVE_IASL:=$(call find-tool,iasl)

ifeq ($(HAVE_IASL),n)
$(error To build LinuxBIOS, you need to install the 'iasl' tool)
endif


ifeq ($(CONFIG_PLATFORM_CHEETAH_FAM10),y)
ifeq ($(CONFIG_PAYLOAD_LAB),y)
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/serengeti_cheetah_fam10-lab.patch
endif
endif

ifeq ($(CONFIG_PLATFORM_SERENGETI_CHEETAH),y)
ifeq ($(CONFIG_PAYLOAD_LAB),y)
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/serengeti_cheetah-lab.patch
else
	LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/serengeti_cheetah-payload.patch
endif

ifeq ($(CONFIG_SIMNOW),y)
LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/simnow.patch
endif
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
	@ cp $< $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
