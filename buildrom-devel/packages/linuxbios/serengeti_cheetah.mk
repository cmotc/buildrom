# This is the Generic LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

LINUXBIOS_PATCHES =

# Make sure we have the tools we need to accomplish this
HAVE_IASL:=$(call find-tool,iasl)

ifeq ($(HAVE_IASL),n)
$(error To build LinuxBIOS, you need to install the 'iasl' tool)
endif


ifeq ($(CONFIG_PAYLOAD_LAB),y)
	LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/serengeti_cheetah-lab.patch
else
	LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/serengeti_cheetah-payload.patch
endif

ifeq ($(CONFIG_SIMNOW),y)
LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/simnow.patch
endif

LINUXBIOS_BASE_DIR=svn
LINUXBIOS_URL=svn://linuxbios.org/repos/trunk/LinuxBIOSv2
LINUXBIOS_TARBALL=linuxbios-svn-$(LINUXBIOS_TAG).tar.gz
LINUXBIOS_PAYLOAD_TARGET=$(LINUXBIOS_BUILD_DIR)/payload.elf
TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LINUXBIOS_TARBALL):
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchsvn.sh $(LINUXBIOS_URL) $(SOURCE_DIR)/linuxbios \
	$(LINUXBIOS_TAG) $(SOURCE_DIR)/$(LINUXBIOS_TARBALL) \
	> $(LINUXBIOS_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(LINUXBIOS_OUTPUT)
	@ cp $< $@

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
linuxbios-distclean: generic-linuxbios-distclean
