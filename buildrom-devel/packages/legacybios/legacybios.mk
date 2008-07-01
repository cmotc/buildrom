LEGACYBIOS_URL=git://git.linuxtogo.org/home/kevin/legacybios/
LEGACYBIOS_TAG=master

LEGACYBIOS_DIR=$(BUILD_DIR)/legacybios
LEGACYBIOS_SRC_DIR=$(LEGACYBIOS_DIR)/legacybios-$(LEGACYBIOS_TAG)
LEGACYBIOS_STAMP_DIR=$(LEGACYBIOS_DIR)/stamps
LEGACYBIOS_LOG_DIR=$(LEGACYBIOS_DIR)/logs

LEGACYBIOS_PATCHES=hardcode.diff

ifeq ($(CONFIG_VERBOSE),y)
LEGACYBIOS_FETCH_LOG=/dev/stdout
LEGACYBIOS_BUILD_LOG=/dev/stdout
else
LEGACYBIOS_BUILD_LOG=$(LEGACYBIOS_LOG_DIR)/build.log
LEGACYBIOS_FETCH_LOG=$(LEGACYBIOS_LOG_DIR)/fetch.log
endif

LEGACYBIOS_TARBALL=legacybios.tar

ifeq ($(shell if [ -f $(PACKAGE_DIR)/legacybios/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	LEGACYBIOS_CONFIG = customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
endif

$(SOURCE_DIR)/$(LEGACYBIOS_TARBALL): | $(LEGACYBIOS_STAMP_DIR) $(LEGACYBIOS_LOG_DIR)
	@ echo "Fetching LegacyBIOS..."
	@ mkdir -p $(SOURCE_DIR)
	@ $(BIN_DIR)/fetchgit.sh $(LEGACYBIOS_URL) $(SOURCE_DIR)/legacybios $(LEGACYBIOS_TAG) $(SOURCE_DIR)/$(LEGACYBIOS_TARBALL) legacybios > $(LEGACYBIOS_FETCH_LOG) 2>&1

$(LEGACYBIOS_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LEGACYBIOS_TARBALL) | $(LEGACYBIOS_STAMP_DIR) $(LEGACYBIOS_DIR) $(LEGACYBIOS_LOG_DIR)
	@ echo "Unpacking LegacyBIOS..."
	@ tar -C $(LEGACYBIOS_DIR) -xf $(SOURCE_DIR)/$(LEGACYBIOS_TARBALL)
	@ touch $@      

$(LEGACYBIOS_SRC_DIR)/out/bios.bin: $(LEGACYBIOS_STAMP_DIR)/.unpacked
	@ echo "Building LegacyBIOS..."
	@ make -C $(LEGACYBIOS_SRC_DIR) > $(LEGACYBIOS_BUILD_LOG) 2>&1

$(LEGACYBIOS_STAMP_DIR) $(LEGACYBIOS_LOG_DIR):
	@ mkdir -p $@

$(LEGACYBIOS_STAMP_DIR)/.copied:  $(LEGACYBIOS_SRC_DIR)/out/bios.bin
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(LEGACYBIOS_SRC_DIR)/out/bios.bin.elf $(PAYLOAD_ELF)
	@ touch $@

legacybios: $(LEGACYBIOS_STAMP_DIR)/.copied
	@ cp $(LEGACYBIOS_SRC_DIR)/out/bios.bin.elf $(LEGACYBIOS_SRC_DIR)/legacybios.elf

legacybios-clean:
	@ echo "Cleaning LegacyBIOS..."
	@ rm -f $(LEGACYBIOS_STAMP_DIR)/.copied
ifneq ($(wildcard $(LEGACYBIOS_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(LEGACYBIOS_SRC_DIR) clean > /dev/null 2>&1
endif

legacybios-distclean:
	@ rm -rf $(LEGACYBIOS_DIR)/*

