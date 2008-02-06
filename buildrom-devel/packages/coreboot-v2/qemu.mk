# This is the QEMU coreboot target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(CBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

CBV2_PATCHES =

CBV2_BASE_DIR=svn
TARGET_ROM = $(COREBOOT_VENDOR)-$(COREBOOT_BOARD).rom
CBV2_PAYLOAD_TARGET=$(CBV2_BUILD_DIR)/payload.$(CBV2_PAYLOAD_FILE_EXT)

ifeq ($(CONFIG_PAYLOAD_LAB),y)
	CBV2_CONFIG = Config-lab.lb
	CBV2_PAYLOAD_FILE_EXT = elf.lzma
endif

CBV2_URL=svn://coreboot.org/repos/trunk/coreboot-v2
CBV2_TARBALL=coreboot-svn-$(CBV2_TAG).tar.gz
CBV2_SVN_DIR=$(SOURCE_DIR)/coreboot

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

$(SOURCE_DIR)/$(CBV2_TARBALL):
	@ echo "Fetching the coreboot code..."
	@ mkdir -p $(SOURCE_DIR)/coreboot
	@ $(BIN_DIR)/fetchsvn.sh $(CBV2_URL) $(CBV2_SVN_DIR) \
	$(CBV2_TAG) $(SOURCE_DIR)/$(CBV2_TARBALL) \
	> $(CBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(CBV2_OUTPUT)
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $< $@

coreboot: $(OUTPUT_DIR)/$(TARGET_ROM)
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
