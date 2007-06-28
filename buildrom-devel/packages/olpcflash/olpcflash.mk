OLPCFLASH_DIR=$(BUILD_DIR)/olpcflash
OLPCFLASH_SRC_DIR=$(OLPCFLASH_DIR)/olpcflash
OLPCFLASH_STAMP_DIR=$(OLPCFLASH_DIR)/stamps
OLPCFLASH_LOG_DIR=$(OLPCFLASH_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
OLPCFLASH_BUILD_LOG=/dev/stdout
OLPCFLASH_INSTALL_LOG=/dev/stdout
else
OLPCFLASH_BUILD_LOG=$(OLPCFLASH_LOG_DIR)/build.log
OLPCFLASH_INSTALL_LOG=$(OLPCFLASH_LOG_DIR)/install.log
endif

$(OLPCFLASH_SRC_DIR)/olpcflash.c: $(PACKAGE_DIR)/olpcflash/Makefile $(PACKAGE_DIR)/olpcflash/olpcflash.c
	@ mkdir -p $(OLPCFLASH_SRC_DIR)
	@ cp $(PACKAGE_DIR)/olpcflash/Makefile $(OLPCFLASH_SRC_DIR)
	@ cp $(PACKAGE_DIR)/olpcflash/olpcflash.c $(OLPCFLASH_SRC_DIR)

$(OLPCFLASH_SRC_DIR)/olpcflash: $(OLPCFLASH_SRC_DIR)/olpcflash.c
	@ echo "Building olpcflash..."
	@ $(MAKE) -C $(OLPCFLASH_SRC_DIR) > $(OLPCFLASH_BUILD_LOG) 2>&1

$(INITRD_DIR)/bin/olpcflash: $(OLPCFLASH_SRC_DIR)/olpcflash
	@ install -d $(INITRD_DIR)/bin
	@ install -m 0755 $(OLPCFLASH_SRC_DIR)/olpcflash $@
	@ $(STRIP) $(INITRD_DIR)/bin/olpcflash

$(OLPCFLASH_STAMP_DIR) $(OLPCFLASH_LOG_DIR):
	@ mkdir -p $@

olpcflash: $(OLPCFLASH_STAMP_DIR) $(OLPCFLASH_LOG_DIR) $(INITRD_DIR)/bin/olpcflash

olpcflash-clean:
	@ echo "Cleaning olpcflash..."
	@ $(MAKE) -C $(OLPCFLASH_SRC_DIR) clean > /dev/null 2>&1

olpcflash-distclean:
	@ rm -rf $(OLPCFLASH_DIR)/*

olpcflash-bom:
	@ echo "Package: olpcflash"
	@ echo "Source: (local) buildrom/packages/olpcflash/olpcflash.c"
	@ echo ""
