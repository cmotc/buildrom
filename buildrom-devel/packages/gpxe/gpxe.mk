GPXE_URL=git://git.etherboot.org/scm/gpxe.git
GPXE_DIR=$(BUILD_DIR)/gpxe
GPXE_TAG=master
GPXE_SRC_DIR=$(GPXE_DIR)/gpxe-$(GPXE_TAG)/src
GPXE_SOURCE=gpxe-$(GPXE_TAG).tar.bz2
GPXE_STAMP_DIR=$(GPXE_DIR)/stamps
GPXE_LOG_DIR=$(GPXE_DIR)/logs

ifeq ($(GPXE_ARCH),)
GPXE_ARCH=i386
endif

GPXE_PATCHES = 

# Filter the quotes off the config string
GPXE_DRIVER := $(shell echo $(CONFIG_GPXE_DRIVER) | sed -e s:\"::g)
GPXE_OUTPUT=$(GPXE_SRC_DIR)/bin/$(GPXE_DRIVER).elf

ifeq ($(CONFIG_VERBOSE),y)
GPXE_FETCH_LOG=/dev/stdout
GPXE_BUILD_LOG=/dev/stdout
GPXE_INSTALL_LOG=/dev/stdout
else
GPXE_FETCH_LOG=$(GPXE_LOG_DIR)/fetch.log
GPXE_BUILD_LOG=$(GPXE_LOG_DIR)/build.log
GPXE_INSTALL_LOG=$(GPXE_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(GPXE_SOURCE):
	@ echo "Fetching the GPXE source..."
	$(BIN_DIR)/fetchgit.sh $(GPXE_URL) $(SOURCE_DIR)/gpxe \
	$(GPXE_TAG) $(SOURCE_DIR)/$(GPXE_SOURCE) gpxe \
	> $(GPXE_FETCH_LOG) 2>&1

$(GPXE_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(GPXE_SOURCE)
	@ echo "Unpacking GPXE..."
	@ tar -C $(GPXE_DIR) -jxf $(SOURCE_DIR)/$(GPXE_SOURCE)
	@ touch $@	

$(GPXE_STAMP_DIR)/.patched: $(GPXE_STAMP_DIR)/.unpacked
	@ echo "Patching GPXE..."
	@ $(BIN_DIR)/doquilt.sh $(GPXE_SRC_DIR)/.. $(GPXE_PATCHES)
	@ touch $@

$(GPXE_STAMP_DIR)/.configured: $(GPXE_STAMP_DIR)/.patched
	@ cp $(PACKAGE_DIR)/gpxe/conf/Config.main \
	$(GPXE_SRC_DIR)/Config
	@ cp $(PACKAGE_DIR)/gpxe/conf/Config.$(GPXE_ARCH) \
	$(GPXE_SRC_DIR)/arch/$(GPXE_ARCH)/Config
	@ touch $@

$(GPXE_OUTPUT): $(GPXE_STAMP_DIR)/.configured
	@ echo "Building GPXE..."
	@ ( unset CFLAGS; export EXTRA_CFLAGS="$(CFLAGS)"; \
	unset ASFLAGS; export EXTRA_ASFLAGS="$(ASFLAGS)"; \
	unset LDFLAGS; \
	$(MAKE) -C $(GPXE_SRC_DIR) ARCH=$(GPXE_ARCH) \
	bin/$(GPXE_DRIVER).elf > $(GPXE_BUILD_LOG) 2>&1)

$(GPXE_STAMP_DIR) $(GPXE_LOG_DIR):
	@ mkdir -p $@

gpxe: $(GPXE_STAMP_DIR) $(GPXE_LOG_DIR) $(GPXE_OUTPUT) 
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $(GPXE_OUTPUT) $(PAYLOAD_ELF)

gpxe-clean:
	@ echo "Cleaning GPXE..."
	@ $(MAKE) -C $(GPXE_SRC_DIR) clean > /dev/null 2>&1

gpxe-distclean:
	@ rm -rf $(GPXE_DIR)/*
