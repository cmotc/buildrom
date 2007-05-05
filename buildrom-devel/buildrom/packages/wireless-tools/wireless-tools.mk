WIRELESS_URL=http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux
WIRELESS_SOURCE=wireless_tools.28.pre13.tar.gz
WIRELESS_DIR=$(BUILD_DIR)/wireless-tools
WIRELESS_SRC_DIR=$(WIRELESS_DIR)/wireless_tools.28
WIRELESS_STAMP_DIR=$(WIRELESS_DIR)/stamps
WIRELESS_LOG_DIR=$(WIRELESS_DIR)/logs
WIRELESS_PATCH=$(PACKAGE_DIR)/wireless-tools/ldfix.patch
WIRELESS_BINARIES=iwconfig

ifeq ($(VERBOSE),y)
WIRELESS_BUILD_LOG=/dev/stdout
WIRELESS_INSTALL_LOG=/dev/stdout
else
WIRELESS_BUILD_LOG=$(WIRELESS_LOG_DIR)/build.log
WIRELESS_INSTALL_LOG=$(WIRELESS_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(WIRELESS_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(WIRELESS_URL)/$(WIRELESS_SOURCE)

$(WIRELESS_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(WIRELESS_SOURCE)
	@ echo "Unpacking wireless-tools..."
	@ tar -C $(WIRELESS_DIR) -zxf $(SOURCE_DIR)/$(WIRELESS_SOURCE)
	@ touch $@	

$(WIRELESS_STAMP_DIR)/.patched: $(WIRELESS_STAMP_DIR)/.unpacked
	@ cat $(WIRELESS_PATCH) | patch -d $(WIRELESS_SRC_DIR) -p1
	@ touch $@

$(WIRELESS_SRC_DIR)/iwconfig: $(WIRELESS_STAMP_DIR)/.patched
	@ echo "Building wireless-tools..."
	@ $(MAKE) -C $(WIRELESS_SRC_DIR) -e LIBS="$(LIBS) -lm" \
	'INSTALL_DIR=$(INITRD_DIR)/sbin' all > $(WIRELESS_BUILD_LOG) 2>&1

$(INITRD_DIR)/sbin/iwconfig: $(WIRELESS_SRC_DIR)/iwconfig
	@ echo "Installing wireless-tools..."
	
	@ $(MAKE) -C $(WIRELESS_SRC_DIR) LDCONFIG=true \
	PREFIX=$(INITRD_DIR) install-dynamic > $(WIRELESS_INSTALL_LOG) 2>&1

	@ for file in $(WIRELESS_BINARIES); do \
	install -m 755 $(WIRELESS_SRC_DIR)/$$file $(INITRD_DIR)/sbin; \
	$(STRIP) $(INITRD_DIR)/sbin/$$file; \
	done

$(WIRELESS_STAMP_DIR) $(WIRELESS_LOG_DIR):
	@ mkdir -p $@

wireless-tools: $(WIRELESS_STAMP_DIR) $(WIRELESS_LOG_DIR) $(INITRD_DIR)/sbin/iwconfig

wireless-tools-clean:
	@ echo "Cleaning wireless-tools..."
	@ $(MAKE) -C $(WIRELESS_SRC_DIR) realclean > /dev/null 2>&1
	@ rm -f $(WIRELESS_SRC_DIR)/.config

wireless-tools-distclean:
	@ rm -rf $(WIRELESS_DIR)/*

wireless-tools-bom:
	@ echo "Package: wireless-tools"
	@ echo "Source: $(WIRELESS_URL)/$(WIRELESS_SOURCE)"
	@ echo -n "Patches: "
	@ for file in $(WIRELESS_PATCH); do \
		echo -n `basename $$file`; \
	done
	@ echo ""
	@ echo ""
