BUSYBOX_URL=http://busybox.net/downloads
BUSYBOX_SOURCE=busybox-1.1.3.tar.bz2
BUSYBOX_DIR=$(BUILD_DIR)/busybox
BUSYBOX_SRC_DIR=$(BUSYBOX_DIR)/busybox-1.1.3
BUSYBOX_STAMP_DIR=$(BUSYBOX_DIR)/stamps
BUSYBOX_LOG_DIR=$(BUSYBOX_DIR)/logs

ifeq ($(VERBOSE),y)
BUSYBOX_BUILD_LOG=/dev/stdout
BUSYBOX_INSTALL_LOG=/dev/stdout
else
BUSYBOX_BUILD_LOG=$(BUSYBOX_LOG_DIR)/build.log
BUSYBOX_INSTALL_LOG=$(BUSYBOX_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(BUSYBOX_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(BUSYBOX_URL)/$(BUSYBOX_SOURCE)

$(BUSYBOX_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(BUSYBOX_SOURCE)
	@ echo "Unpacking busybox..."
	@ tar -C $(BUSYBOX_DIR) -jxf $(SOURCE_DIR)/$(BUSYBOX_SOURCE)
	@ touch $@	
	
$(BUSYBOX_SRC_DIR)/.config: $(BUSYBOX_STAMP_DIR)/.unpacked
	@ cp $(PACKAGE_DIR)/busybox/conf/defconfig $@

$(BUSYBOX_SRC_DIR)/busybox: $(BUSYBOX_SRC_DIR)/.config
	@ echo "Building busybox..."
	@ ( unset CFLAGS; export EXTRA_CFLAGS="$(CFLAGS)"; \
	$(MAKE) -C $(BUSYBOX_SRC_DIR) VERBOSE=y \
	LIBRARIES="$(LIBS)" all > $(BUSYBOX_BUILD_LOG) 2>&1)

$(INITRD_DIR)/bin/busybox: $(BUSYBOX_SRC_DIR)/busybox
	@ $(MAKE) -C $(BUSYBOX_SRC_DIR) \
	PREFIX=$(INITRD_DIR) install > $(BUSYBOX_INSTALL_LOG) 2>&1

$(BUSYBOX_STAMP_DIR) $(BUSYBOX_LOG_DIR):
	@ mkdir -p $@

busybox: $(BUSYBOX_STAMP_DIR) $(BUSYBOX_LOG_DIR) $(INITRD_DIR)/bin/busybox

busybox-clean:
	@ echo "Cleaning busybox..."
	@ $(MAKE) -C $(BUSYBOX_SRC_DIR) clean > /dev/null 2>&1

busybox-distclean:
	@ rm -rf $(BUSYBOX_DIR)/*

.PHONY: busybox-message
