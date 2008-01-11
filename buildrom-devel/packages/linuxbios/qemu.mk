# This is the QEMU LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LBV2_PATCHES =

LBV2_BASE_DIR=svn
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom
LBV2_PAYLOAD_TARGET=$(LBV2_BUILD_DIR)/payload.elf

ifeq ($(CONFIG_PAYLOAD_LAB),y)
LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/qemu-lab.patch
else
LBV2_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/qemu-payload.patch
endif

LBV2_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
LBV2_TARBALL=linuxbios-svn-$(LBV2_TAG).tar.gz
LBV2_SVN_DIR=$(SOURCE_DIR)/linuxbios

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LBV2_TARBALL):
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LBV2_URL) $(LBV2_SVN_DIR) \
	$(LBV2_TAG) $(SOURCE_DIR)/$(LBV2_TARBALL) \
	> $(LBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LBV2_OUTPUT)
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $< $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
