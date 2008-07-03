SEABIOS_URL=git://git.linuxtogo.org/home/kevin/legacybios/
SEABIOS_TAG=master

SEABIOS_DIR=$(BUILD_DIR)/seabios
SEABIOS_SRC_DIR=$(SEABIOS_DIR)/seabios-$(SEABIOS_TAG)
SEABIOS_STAMP_DIR=$(SEABIOS_DIR)/stamps
SEABIOS_LOG_DIR=$(SEABIOS_DIR)/logs

SEABIOS_PATCHES=$(PACKAGE_DIR)/seabios/hardcode.diff

ifeq ($(CONFIG_VERBOSE),y)
SEABIOS_FETCH_LOG=/dev/stdout
SEABIOS_BUILD_LOG=/dev/stdout
else
SEABIOS_BUILD_LOG=$(SEABIOS_LOG_DIR)/build.log
SEABIOS_FETCH_LOG=$(SEABIOS_LOG_DIR)/fetch.log
endif

SEABIOS_TARBALL=seabios.tar

ifeq ($(shell if [ -f $(PACKAGE_DIR)/seabios/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	SEABIOS_CONFIG = customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
endif

$(SOURCE_DIR)/$(SEABIOS_TARBALL): | $(SEABIOS_STAMP_DIR) $(SEABIOS_LOG_DIR)
	@ echo "Fetching SeaBIOS..."
	@ mkdir -p $(SOURCE_DIR)
	@ $(BIN_DIR)/fetchgit.sh $(SEABIOS_URL) $(SOURCE_DIR)/seabios $(SEABIOS_TAG) $(SOURCE_DIR)/$(SEABIOS_TARBALL) seabios > $(SEABIOS_FETCH_LOG) 2>&1

$(SEABIOS_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(SEABIOS_TARBALL) | $(SEABIOS_STAMP_DIR) $(SEABIOS_DIR) $(SEABIOS_LOG_DIR)
	@ echo "Unpacking SeaBIOS..."
	@ tar -C $(SEABIOS_DIR) -xf $(SOURCE_DIR)/$(SEABIOS_TARBALL)
	@ touch $@      

$(SEABIOS_STAMP_DIR)/.patched: $(SEABIOS_STAMP_DIR)/.unpacked
	@ echo "Patching mkelfimage..."
	@ $(BIN_DIR)/doquilt.sh $(SEABIOS_SRC_DIR) $(SEABIOS_PATCHES)
	@ touch $@

$(SEABIOS_SRC_DIR)/out/bios.bin: $(SEABIOS_STAMP_DIR)/.patched
	@ echo "Building SeaBIOS..."
	@ make -C $(SEABIOS_SRC_DIR) > $(SEABIOS_BUILD_LOG) 2>&1

$(SEABIOS_STAMP_DIR) $(SEABIOS_LOG_DIR):
	@ mkdir -p $@

$(SEABIOS_STAMP_DIR)/.copied:  $(SEABIOS_SRC_DIR)/out/bios.bin
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(SEABIOS_SRC_DIR)/out/bios.bin.elf $(PAYLOAD_ELF)
	@ touch $@

seabios: $(SEABIOS_STAMP_DIR)/.copied
	@ cp $(SEABIOS_SRC_DIR)/out/bios.bin.elf $(SEABIOS_SRC_DIR)/seabios.elf

seabios-clean:
	@ echo "Cleaning SeaBIOS..."
	@ rm -f $(SEABIOS_STAMP_DIR)/.copied
ifneq ($(wildcard $(SEABIOS_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(SEABIOS_SRC_DIR) clean > /dev/null 2>&1
endif

seabios-distclean:
	@ rm -rf $(SEABIOS_DIR)/*

