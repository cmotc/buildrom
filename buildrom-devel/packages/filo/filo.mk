FILO_URL=svn://coreboot.org/filo/trunk/filo-0.5
FILO_TAG=44

FILO_DIR=$(BUILD_DIR)/filo
FILO_SRC_DIR=$(FILO_DIR)/svn
FILO_STAMP_DIR=$(FILO_DIR)/stamps
FILO_LOG_DIR=$(FILO_DIR)/logs

FILO_PATCHES=$(PACKAGE_DIR)/filo/patches/make.patch

ifeq ($(CONFIG_VERBOSE),y)
FILO_FETCH_LOG=/dev/stdout
FILO_BUILD_LOG=/dev/stdout
FILO_INSTALL_LOG=/dev/stdout
else
FILO_BUILD_LOG=$(FILO_LOG_DIR)/build.log
FILO_INSTALL_LOG=$(FILO_LOG_DIR)/install.log
FILO_FETCH_LOG=$(FILO_LOG_DIR)/fetch.log
endif

FILO_TARBALL=filo-svn-$(FILO_TAG).tar.gz

ifeq ($(shell if [ -f $(PACKAGE_DIR)/filo/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	FILO_CONFIG = customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
endif

$(SOURCE_DIR)/$(FILO_TARBALL): 
	@ mkdir -p $(SOURCE_DIR)/filo
	@ $(BIN_DIR)/fetchsvn.sh $(FILO_URL) $(SOURCE_DIR)/filo \
	$(FILO_TAG) $(SOURCE_DIR)/$(FILO_TARBALL) \
	> $(FILO_FETCH_LOG) 2>&1

$(FILO_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(FILO_TARBALL) | $(FILO_STAMP_DIR) $(FILO_DIR)
	@ echo "Unpacking filo..."
	@ tar -C $(FILO_DIR) -zxf $(SOURCE_DIR)/$(FILO_TARBALL)
	@ touch $@      

$(FILO_STAMP_DIR)/.patched: $(FILO_STAMP_DIR)/.unpacked
	@ echo "Patching filo..."
	@ $(BIN_DIR)/doquilt.sh $(FILO_SRC_DIR) $(FILO_PATCHES)
	@ touch $@

$(FILO_STAMP_DIR)/.configured: $(FILO_STAMP_DIR)/.patched
	@ make -C $(FILO_SRC_DIR) config > $(FILO_BUILD_LOG) 2>&1
	@ cp $(PACKAGE_DIR)/filo/conf/$(FILO_CONFIG) $(FILO_SRC_DIR)/Config
	@ touch $@

$(FILO_SRC_DIR)/filo.elf: $(FILO_STAMP_DIR)/.configured
	@ echo "Building filo..."
ifeq ($(findstring customconfig,$(FILO_CONFIG)),customconfig)
	@ echo "Using custom config $(PACKAGE_DIR)/filo/conf/$(FILO_CONFIG)"
endif
	@ make -C $(FILO_SRC_DIR) filo.elf > $(FILO_BUILD_LOG) 2>&1
	@ mkdir -p $(OUTPUT_DIR)/config/filo
	@ cp $(FILO_SRC_DIR)/Config $(OUTPUT_DIR)/config/filo/

$(FILO_STAMP_DIR)/.copied: $(FILO_SRC_DIR)/filo.elf
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(FILO_SRC_DIR)/filo.elf $(PAYLOAD_ELF)
	@ touch $@

$(FILO_STAMP_DIR) $(FILO_LOG_DIR):
	@ mkdir -p $@

filo: $(FILO_STAMP_DIR) $(FILO_LOG_DIR) $(FILO_STAMP_DIR)/.copied

filo-clean:
	@ echo "Cleaning filo..."
ifneq ($(wildcard "$(FILO_SRC_DIR)/Makefile"),)
	@ $(MAKE) -C $(FILO_SRC_DIR) clean > /dev/null 2>&1
endif
	@ rm -f $(FILO_STAMP_DIR)/.copied

filo-distclean:
	@ rm -rf $(FILO_DIR)/*

filo-extract: $(FILO_STAMP_DIR)/.patched

filo-config: | $(FILO_STAMP_DIR)/.configured
ifeq ($(shell if [ -f $(PACKAGE_DIR)/filo/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ echo
	@ echo "Found an existing custom configuration file:"
	@ echo "  $(PACKAGE_DIR)/filo/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)"
	@ echo "Please modify this file by hand."
	@ echo "Remove the above file and re-run this command if you want to create a new custom configuration from scratch for this payload/board."
	@ echo
else
	@ echo "Configure filo..."
	@ $(MAKE) -C $(FILO_SRC_DIR) config
	@ cp -f $(FILO_SRC_DIR)/Config $(PACKAGE_DIR)/filo/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
	@ echo
	@ echo "Your custom FILO config has been saved as "
	@ echo "  $(PACKAGE_DIR)/filo/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)"
	@ echo "Please edit it to your liking."
	@ echo
endif

