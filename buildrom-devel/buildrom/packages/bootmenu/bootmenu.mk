BOOTMENU_URL=http://crank.laptop.org/~jcrouse/
BOOTMENU_SOURCE=bootmenu-0.1.tar.gz
BOOTMENU_DIR=$(BUILD_DIR)/bootmenu
BOOTMENU_SRC_DIR=$(BOOTMENU_DIR)/bootmenu-0.1
BOOTMENU_STAMP_DIR=$(BOOTMENU_DIR)/stamps
BOOTMENU_LOG_DIR=$(BOOTMENU_DIR)/logs

ifeq ($(VERBOSE),y)
BOOTMENU_BUILD_LOG=/dev/stdout
BOOTMENU_INSTALL_LOG=/dev/stdout
else
BOOTMENU_BUILD_LOG=$(BOOTMENU_LOG_DIR)/build.log
BOOTMENU_INSTALL_LOG=$(BOOTMENU_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(BOOTMENU_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(BOOTMENU_URL)/$(BOOTMENU_SOURCE)

$(BOOTMENU_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(BOOTMENU_SOURCE)
	@ echo "Unpacking bootmenu..."
	@ tar -C $(BOOTMENU_DIR) -zxf $(SOURCE_DIR)/$(BOOTMENU_SOURCE)
	@ touch $@	

$(BOOTMENU_SRC_DIR)/bootmenu: $(BOOTMENU_STAMP_DIR)/.unpacked
	@ echo "Building bootmenu..."
	@ $(MAKE) -C $(BOOTMENU_SRC_DIR) > $(BOOTMENU_BUILD_LOG) 2>&1

$(INITRD_DIR)/bin/bootmenu: $(BOOTMENU_SRC_DIR)/bootmenu
	@ install -d $(INITRD_DIR)/bin
	@ install -m 0755 $(BOOTMENU_SRC_DIR)/bootmenu \
	$(INITRD_DIR)/bin/bootmenu
	@ install -d $(INITRD_DIR)/bin/images
	@ install -m 0644 $(BOOTMENU_SRC_DIR)/images/*.ppm $(INITRD_DIR)/bin/images

$(BOOTMENU_STAMP_DIR) $(BOOTMENU_LOG_DIR):
	@ mkdir -p $@

bootmenu: $(BOOTMENU_STAMP_DIR) $(BOOTMENU_LOG_DIR) $(INITRD_DIR)/bin/bootmenu

bootmenu-clean:
	@ echo "Cleaning bootmenu..."
	@ $(MAKE) -C $(BOOTMENU_SRC_DIR) clean > /dev/null 2>&1

bootmenu-distclean:
	@ rm -rf $(BOOTMENU_DIR)/*

