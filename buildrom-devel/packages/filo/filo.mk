FILO_URL=svn://80.190.231.112/filo/trunk/filo-0.5
FILO_TAG=34

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

$(SOURCE_DIR)/$(FILO_TARBALL): 
	@ mkdir -p $(SOURCE_DIR)/filo
	@ $(BIN_DIR)/fetchsvn.sh $(FILO_URL) $(SOURCE_DIR)/filo \
	$(FILO_TAG) $(SOURCE_DIR)/$(FILO_TARBALL) \
	> $(FILO_FETCH_LOG) 2>&1

$(FILO_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(FILO_TARBALL)
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
	@ make -C $(FILO_SRC_DIR) filo.elf > $(FILO_BUILD_LOG) 2>&1

$(FILO_STAMP_DIR) $(FILO_LOG_DIR):
	@ mkdir -p $@

filo: $(FILO_STAMP_DIR) $(FILO_LOG_DIR) $(FILO_SRC_DIR)/filo.elf
	@ mkdir -p $(OUTPUT_DIR)
	@ cp $(FILO_SRC_DIR)/filo.elf $(PAYLOAD_ELF)

filo-clean:
	@ echo "Cleaning filo..."
	@ $(MAKE) -C $(FILO_SRC_DIR) clean > /dev/null 2>&1

filo-distclean:
	@ rm -rf $(FILO_DIR)/*

