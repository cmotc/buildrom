# This is the QEMU LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LINUXBIOS_PATCHES =



LINUXBIOS_BASE_DIR=svn
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom
LINUXBIOS_PAYLOAD_TARGET=$(LINUXBIOS_BUILD_DIR)/payload.elf

ifeq ($(CONFIG_LINUXBIOS_V3),y)
	LINUXBIOS_URL=svn://linuxbios.org/repository/LinuxBIOSv3
	LINUXBIOS_TARBALL=linuxbiosv3-svn-$(LINUXBIOS_TAG).tar.gz
	ifeq ($(CONFIG_LINUXBIOS_V3_LGDT_PATCH),y)
	LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/lgdt.patch
	endif
	LINUXBIOS_SVN_DIR=$(SOURCE_DIR)/linuxbiosv3
else
	ifeq ($(CONFIG_PAYLOAD_LAB),y)
	LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/qemu-lab.patch
	else
	LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/qemu-payload.patch
	endif
	LINUXBIOS_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
	LINUXBIOS_TARBALL=linuxbios-svn-$(LINUXBIOS_TAG).tar.gz
	LINUXBIOS_SVN_DIR=$(SOURCE_DIR)/linuxbios
endif

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LINUXBIOS_TARBALL):
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LINUXBIOS_URL) $(LINUXBIOS_SVN_DIR) \
	$(LINUXBIOS_TAG) $(SOURCE_DIR)/$(LINUXBIOS_TARBALL) \
	> $(LINUXBIOS_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LINUXBIOS_OUTPUT)
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $< $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
