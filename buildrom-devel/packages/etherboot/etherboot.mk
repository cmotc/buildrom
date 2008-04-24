ETHERBOOT_URL=http://internap.dl.sourceforge.net/sourceforge/etherboot
ETHERBOOT_SOURCE=etherboot-5.4.3.tar.bz2
ETHERBOOT_DIR=$(BUILD_DIR)/etherboot
ETHERBOOT_SRC_DIR=$(ETHERBOOT_DIR)/etherboot-5.4.3/src
ETHERBOOT_STAMP_DIR=$(ETHERBOOT_DIR)/stamps
ETHERBOOT_LOG_DIR=$(ETHERBOOT_DIR)/logs

ETHERBOOT_PATCHES += $(PACKAGE_DIR)/etherboot/patches/fix-realmode-stack.patch

# Filter the quotes off the config string
ETHERBOOT_DRIVER := $(shell echo $(CONFIG_ETHERBOOT_DRIVER) | sed -e s:\"::g)
ETHERBOOT_OUTPUT=$(ETHERBOOT_SRC_DIR)/bin/$(ETHERBOOT_DRIVER).zelf

ifeq ($(CONFIG_VERBOSE),y)
ETHERBOOT_BUILD_LOG=/dev/stdout
ETHERBOOT_INSTALL_LOG=/dev/stdout
else
ETHERBOOT_BUILD_LOG=$(ETHERBOOT_LOG_DIR)/build.log
ETHERBOOT_INSTALL_LOG=$(ETHERBOOT_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(ETHERBOOT_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(ETHERBOOT_URL)/$(ETHERBOOT_SOURCE)

$(ETHERBOOT_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(ETHERBOOT_SOURCE)
	@ echo "Unpacking etherboot..."
	@ tar -C $(ETHERBOOT_DIR) -jxf $(SOURCE_DIR)/$(ETHERBOOT_SOURCE)
	@ touch $@	

$(ETHERBOOT_STAMP_DIR)/.patched: $(ETHERBOOT_STAMP_DIR)/.unpacked
	@ echo "Patching etherboot..."
	@ $(BIN_DIR)/doquilt.sh $(ETHERBOOT_SRC_DIR)/.. $(ETHERBOOT_PATCHES)
	@ touch $@

$(ETHERBOOT_STAMP_DIR)/.configured: $(ETHERBOOT_STAMP_DIR)/.patched
	@ cp $(PACKAGE_DIR)/etherboot/conf/Config.main \
	$(ETHERBOOT_SRC_DIR)/Config
	@ cp $(PACKAGE_DIR)/etherboot/conf/Config.$(ETHERBOOT_ARCH) \
	$(ETHERBOOT_SRC_DIR)/arch/$(ETHERBOOT_ARCH)/Config
	@ touch $@

$(ETHERBOOT_OUTPUT): $(ETHERBOOT_STAMP_DIR)/.configured
	@ echo "Building etherboot..."
	@ ( unset CFLAGS; export EXTRA_CFLAGS="$(CFLAGS)"; \
	unset ASFLAGS; export EXTRA_ASFLAGS="$(ASFLAGS)"; \
	unset LDFLAGS; \
	$(MAKE) -C $(ETHERBOOT_SRC_DIR) ARCH=$(ETHERBOOT_ARCH) \
	bin/$(ETHERBOOT_DRIVER).zelf > $(ETHERBOOT_BUILD_LOG) 2>&1)

$(ETHERBOOT_STAMP_DIR) $(ETHERBOOT_LOG_DIR):
	@ mkdir -p $@

etherboot: $(ETHERBOOT_STAMP_DIR) $(ETHERBOOT_LOG_DIR) $(ETHERBOOT_OUTPUT) 
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $(ETHERBOOT_OUTPUT) $(PAYLOAD_ELF)

etherboot-clean:
	@ echo "Cleaning etherboot..."
ifneq ($(wildcard "$(ETHERBOOT_SRC_DIR)/Makefile"),)
	@ $(MAKE) -C $(ETHERBOOT_SRC_DIR) clean > /dev/null 2>&1
endif

etherboot-distclean:
	@ rm -rf $(ETHERBOOT_DIR)/*
