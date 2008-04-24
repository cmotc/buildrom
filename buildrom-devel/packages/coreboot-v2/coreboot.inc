# This is the common code included by all the targets

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(COREBOOT_VENDOR),)
$(error No coreboot vendor specified)
endif
ifeq ($(COREBOOT_BOARD),)
$(error No coreboot board specified)
endif
ifeq ($(CBV2_CONFIG),)
$(error No coreboot config specified)
endif
ifeq ($(CBV2_TDIR),)
$(error No coreboot TDIR specified)
endif
endif

CBV2_OUTPUT=$(CBV2_BUILD_DIR)/coreboot.rom
CBV2_DIR=$(BUILD_DIR)/coreboot

# If the user wanted to override the build directory - obey that now

ifeq ($(CONFIG_CB_USE_BUILD),y)
CBV2_SRC_DIR=$(subst ",,$(CONFIG_CB_BUILDDIR))
else
CBV2_SRC_DIR=$(CBV2_DIR)/$(CBV2_BASE_DIR)
endif

CBV2_TARGET_DIR=$(CBV2_SRC_DIR)/targets/
CBV2_TARGET_NAME=$(COREBOOT_VENDOR)/$(COREBOOT_BOARD)
CBV2_CONFIG_NAME=$(CBV2_TARGET_NAME)/$(CBV2_CONFIG)

CBV2_BUILD_DIR=$(CBV2_TARGET_DIR)/$(CBV2_TARGET_NAME)/$(CBV2_TDIR)

CBV2_STAMP_DIR=$(CBV2_DIR)/stamps
CBV2_LOG_DIR=$(CBV2_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
CBV2_FETCH_LOG=/dev/stdout
CBV2_CONFIG_LOG=/dev/stdout
CBV2_BUILD_LOG=/dev/stdout
CBV2_INSTALL_LOG=/dev/stdout
else
CBV2_FETCH_LOG=$(CBV2_LOG_DIR)/fetch.log
CBV2_BUILD_LOG=$(CBV2_LOG_DIR)/build.log
CBV2_CONFIG_LOG=$(CBV2_LOG_DIR)/config.log
CBV2_INSTALL_LOG=$(CBV2_LOG_DIR)/install.log
endif

# This allows us to skip the unpack/patch/configure stage

ifeq ($(CONFIG_CB_USE_BUILD),y)
CBV2_DIR_TARGET=
else
CBV2_DIR_TARGET=$(CBV2_STAMP_DIR)/.configured
endif

$(CBV2_PAYLOAD_TARGET): $(PAYLOAD_TARGET)
	@ cp $< $@

$(CBV2_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(CBV2_TARBALL) | $(CBV2_STAMP_DIR) $(CBV2_LOG_DIR)
	@ echo "Unpacking coreboot ($(CBV2_TARBALL))..."
	@ tar -C $(CBV2_DIR) -zxf $(SOURCE_DIR)/$(CBV2_TARBALL)
	@ touch $@	

$(CBV2_STAMP_DIR)/.patched: $(CBV2_STAMP_DIR)/.unpacked 
	@ echo "Patching coreboot..."
	@ $(BIN_DIR)/doquilt.sh $(CBV2_SRC_DIR) $(CBV2_PATCHES)
	@ touch $@

$(CBV2_STAMP_DIR)/.configured: $(CBV2_STAMP_DIR)/.patched
	@ echo "Building target..."
	@( cd $(CBV2_TARGET_DIR); \
	./buildtarget $(CBV2_CONFIG_NAME) > $(CBV2_CONFIG_LOG) 2>&1)
	@ touch $@

$(CBV2_STAMP_DIR) $(CBV2_LOG_DIR):
	@ mkdir -p $@

$(CBV2_OUTPUT): $(CBV2_STAMP_DIR) $(CBV2_LOG_DIR) $(CBV2_DIR_TARGET) $(CBV2_PAYLOAD_TARGET)
	@ echo "Building coreboot..."
	@ (export CPU_OPT="$(STACKPROTECT)"; \
	make -C $(CBV2_BUILD_DIR) > $(CBV2_BUILD_LOG) 2>&1)
	@ mkdir -p $(OUTPUT_DIR)/config/coreboot-v2/
	@ cp $(CBV2_BUILD_DIR)/../$(CBV2_CONFIG) $(OUTPUT_DIR)/config/coreboot-v2/
	@ cp $(BASE_DIR)/.config $(OUTPUT_DIR)/config/
	@ mkdir -p $(OUTPUT_DIR)/config/system/
	@ uname -a >$(OUTPUT_DIR)/config/system/uname-a
	@ if [ -f /etc/lsb-release ]; then \
	cp /etc/lsb-release $(OUTPUT_DIR)/config/system/; \
	fi	
	@ if [ -f /etc/debian-version ]; then \
	cp /etc/debian-version $(OUTPUT_DIR)/config/system/; \
	fi
	@ if [ -f /etc/redhat-version ]; then \
	cp /etc/redhat-version $(OUTPUT_DIR)/config/system/; \
	fi
	@ mkdir -p $(OUTPUT_DIR)/config/toolchain/
	@ $(MAKE) --version >$(OUTPUT_DIR)/config/toolchain/$(MAKE)-version
	@ $(CC) --version >$(OUTPUT_DIR)/config/toolchain/$(CC)-version
	@ $(LD) --version >$(OUTPUT_DIR)/config/toolchain/$(LD)-version
ifeq ($(CONFIG_STORE_SVN_INFO),y)
	@ mkdir -p $(OUTPUT_DIR)/config/svn/
	@ svn diff > $(OUTPUT_DIR)/config/svn/svn.diff
	@ svn info > $(OUTPUT_DIR)/config/svn/svn.info
	@ svn status > $(OUTPUT_DIR)/config/svn/svn.status
endif

generic-coreboot-clean:
	@ echo "Cleaning coreboot..."
	@ rm -f $(CBV2_PAYLOAD_TARGET)
ifneq ($(wildcard "$(CBV2_BUILD_DIR)/Makefile"),)
	$(MAKE) -C $(CBV2_BUILD_DIR) clean > /dev/null 2>&1;
endif
	@ rm -f $(CBV2_OUTPUT)

generic-coreboot-distclean:
	@ if [ "$(CONFIG_CB_USE_BUILD)" = "y" ]; then \
	echo "Cleaning coreboot build..."; \
	$(MAKE) -C $(CBV2_BUILD_DIR) clean > /dev/null 2>&1; \
	rm -f $(CBV2_OUTPUT); \
	fi	

	@ rm -rf $(CBV2_DIR)/*

coreboot-extract: $(CBV2_STAMP_DIR)/.patched

