# This is the Generic coreboot target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(CBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

CBV2_PATCHES =

# Make sure we have the tools we need to accomplish this
HAVE_IASL:=$(call find-tool,iasl)

ifeq ($(HAVE_IASL),n)
$(error To build coreboot, you need to install the 'iasl' tool)
endif


ifeq ($(CONFIG_PLATFORM_CHEETAH_FAM10),y)
ifeq ($(CONFIG_PAYLOAD_LAB),y)
	CBV2_PATCHES += $(PACKAGE_DIR)/coreboot-v2/patches/serengeti_cheetah_fam10-lab.patch
endif
endif

ifeq ($(CONFIG_PLATFORM_SERENGETI_CHEETAH),y)
ifeq ($(CONFIG_PAYLOAD_LAB),y)
	CBV2_PATCHES += $(PACKAGE_DIR)/coreboot-v2/patches/serengeti_cheetah-lab.patch
else
	CBV2_PATCHES += $(PACKAGE_DIR)/coreboot-v2/patches/serengeti_cheetah-payload.patch
endif

ifeq ($(CONFIG_SIMNOW),y)
CBV2_PATCHES += $(PACKAGE_DIR)/coreboot-v2/patches/simnow.patch
endif
endif

CBV2_BASE_DIR=svn
CBV2_URL=svn://coreboot.org/repos/trunk/coreboot-v2
CBV2_TARBALL=coreboot-svn-$(CBV2_TAG).tar.gz
CBV2_PAYLOAD_TARGET=$(CBV2_BUILD_DIR)/payload.elf
TARGET_ROM = $(COREBOOT_VENDOR)-$(COREBOOT_BOARD).rom

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

$(SOURCE_DIR)/$(CBV2_TARBALL):
	@ echo "Fetching the coreboot code..."
	@ mkdir -p $(SOURCE_DIR)/coreboot
	@ $(BIN_DIR)/fetchsvn.sh $(CBV2_URL) $(SOURCE_DIR)/coreboot \
	$(CBV2_TAG) $(SOURCE_DIR)/$(CBV2_TARBALL) \
	> $(CBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(CBV2_OUTPUT)
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $< $@

coreboot: $(OUTPUT_DIR)/$(TARGET_ROM)
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
