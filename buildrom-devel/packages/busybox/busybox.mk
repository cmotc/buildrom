BUSYBOX_URL=http://busybox.net/downloads
BUSYBOX_SOURCE=busybox-1.1.3.tar.bz2
BUSYBOX_DIR=$(BUILD_DIR)/busybox
BUSYBOX_SRC_DIR=$(BUSYBOX_DIR)/busybox-1.1.3
BUSYBOX_STAMP_DIR=$(BUSYBOX_DIR)/stamps
BUSYBOX_LOG_DIR=$(BUSYBOX_DIR)/logs
BUSYBOX_PATCHES=$(PACKAGE_DIR)/busybox/testfix.patch $(PACKAGE_DIR)/busybox/regex.patch
BUSYBOX_PATCHES += $(PACKAGE_DIR)/busybox/ipaddress.patch

ifeq ($(CONFIG_VERBOSE),y)
BUSYBOX_BUILD_LOG=/dev/stdout
BUSYBOX_INSTALL_LOG=/dev/stdout
else
BUSYBOX_BUILD_LOG=$(BUSYBOX_LOG_DIR)/build.log
BUSYBOX_INSTALL_LOG=$(BUSYBOX_LOG_DIR)/install.log
endif

BUSYBOX_CONFIG ?= defconfig

ifeq ($(findstring defconfig,$(BUSYBOX_CONFIG)),defconfig)
ifeq ($(shell if [ -f $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	BUSYBOX_CONFIG = customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
endif
endif

$(SOURCE_DIR)/$(BUSYBOX_SOURCE):
	@ echo "Downloading busybox..."
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(BUSYBOX_URL)/$(BUSYBOX_SOURCE)

$(BUSYBOX_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(BUSYBOX_SOURCE) | $(BUSYBOX_STAMP_DIR) $(BUSYBOX_DIR)
	@ echo "Unpacking busybox..."
	@ tar -C $(BUSYBOX_DIR) -jxf $(SOURCE_DIR)/$(BUSYBOX_SOURCE)
	@ touch $@	

$(BUSYBOX_STAMP_DIR)/.patched: $(BUSYBOX_STAMP_DIR)/.unpacked
	@ echo "Patching busybox..."
	@ $(BIN_DIR)/doquilt.sh $(BUSYBOX_SRC_DIR) $(BUSYBOX_PATCHES)
	@ touch $@

$(BUSYBOX_SRC_DIR)/.config: $(BUSYBOX_STAMP_DIR)/.patched
	@ cp -f $(PACKAGE_DIR)/busybox/conf/$(BUSYBOX_CONFIG) $@

$(BUSYBOX_SRC_DIR)/busybox: $(BUSYBOX_SRC_DIR)/.config | $(BUSYBOX_LOG_DIR)
	@ echo "Building busybox..."
ifneq ($(findstring defconfig,$(BUSYBOX_CONFIG)),defconfig)
	@ echo "Using custom config $(PACKAGE_DIR)/busybox/conf/$(BUSYBOX_CONFIG)"
endif
	@ ( unset CFLAGS; unset LDFLAGS; \
	export EXTRA_CFLAGS="$(CFLAGS)";\
	export LDFLAGS="$(LDFLAGS_orig)";\
	$(MAKE) -C $(BUSYBOX_SRC_DIR) VERBOSE=y \
	LIBRARIES="$(LIBS)" all > $(BUSYBOX_BUILD_LOG) 2>&1)
	@ mkdir -p $(OUTPUT_DIR)/config/busybox
	@ cp $(BUSYBOX_SRC_DIR)/.config $(OUTPUT_DIR)/config/busybox/


$(INITRD_DIR)/bin/busybox: $(BUSYBOX_SRC_DIR)/busybox | $(BUSYBOX_LOG_DIR)
	@ $(MAKE) -C $(BUSYBOX_SRC_DIR) \
	PREFIX=$(INITRD_DIR) install > $(BUSYBOX_INSTALL_LOG) 2>&1

$(BUSYBOX_STAMP_DIR) $(BUSYBOX_LOG_DIR) $(BUSYBOX_DIR):
	@ mkdir -p $@

busybox: $(INITRD_DIR)/bin/busybox

busybox-clean:
	@ echo "Cleaning busybox..."
ifneq ($(wildcard "$(BUSYBOX_SRC_DIR)/Makefile"),)
	@ $(MAKE) -C $(BUSYBOX_SRC_DIR) clean > /dev/null 2>&1
endif

busybox-distclean:
	@ rm -rf $(BUSYBOX_DIR)/*

busybox-bom:
	@ echo "Package: busybox"
	@ echo "Source: $(BUSYBOX_URL)/$(BUSYBOX_SOURCE)"
	@ echo ""

busybox-extract: $(BUSYBOX_STAMP_DIR)/.patched

busybox-config: | $(BUSYBOX_SRC_DIR)/.config
ifeq ($(shell if [ -f $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ cp -f $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) $(BUSYBOX_SRC_DIR)/.config
endif
ifeq (busybox,$(filter busybox,$(PAYLOAD-y)))
	@ echo "Configure busybox..."
	@ $(MAKE) -C $(BUSYBOX_SRC_DIR) menuconfig
	@ echo
ifeq ($(shell if [ -f $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ echo "Found an existing custom configuration file:"
	@ echo "  $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)"
	@ echo "I've copied it back to the source directory for modification."
	@ echo "Remove the above file and re-run this command if you want to create a new custom configuration from scratch for this payload/board."
	@ echo
endif
	@ cp -f $(BUSYBOX_SRC_DIR)/.config $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
	@ echo "Your custom busybox config file has been saved as $(PACKAGE_DIR)/busybox/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)."
	@ echo
else
	@ echo "Your payload does not require busybox."
endif
