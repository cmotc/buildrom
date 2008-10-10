# This is the common code included by all the targets

ifeq ($(CONFIG_USE_LZMA),y)
	CBV2_CONFIG=Config-lab.lb
	CBV2_PAYLOAD_FILE_EXT=elf.lzma
ifeq ($(COREBOOT_BOARD),s2881)
	CBV2_PATCHES += $(PACKAGE_DIR)/coreboot-v2/patches/s2881-lab-vga-fix.patch 
endif
else
	CBV2_CONFIG=Config.lb
	CBV2_PAYLOAD_FILE_EXT=elf
endif

ifeq ($(CONFIG_CB_CUSTOM_REV),y)
$(warning Using custom rev $(CONFIG_CB_REVISION))
CBV2_TAG=$(CONFIG_CB_REVISION)
endif

CBV2_BASE_DIR=svn
CBV2_URL=svn://coreboot.org/repos/trunk/coreboot-v2
CBV2_TARBALL=coreboot-svn-$(CBV2_TAG).tar.gz
CBV2_PAYLOAD_TARGET=$(CBV2_BUILD_DIR)/payload.$(CBV2_PAYLOAD_FILE_EXT)
TARGET_ROM=$(COREBOOT_VENDOR)-$(COREBOOT_BOARD).rom

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(CBV2_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
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

# This is the list of components that comprise the ROM (excluding the payload)
CBV2_COMPONENTS= $(CBV2_PREPEND) $(CBV2_OUTPUT)

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
CBV2_DIR_TARGET=$(CBV2_STAMP_DIR)/.configured-$(COREBOOT_BOARD)
endif

# If an optionrom was specified in the configuration, then use it

ifneq ($(OPTIONROM_ID),)
include $(PACKAGE_DIR)/coreboot-v2/optionroms.inc

# Add it to the front of the list so it is prepended to the coreboot output
CBV2_COMPONENTS := $(SOURCE_DIR)/$(OPTIONROM_ID).rom $(CBV2_COMPONENTS)
endif

$(CBV2_PAYLOAD_TARGET): $(PAYLOAD_TARGET)
	@ cp $< $@

$(CBV2_STAMP_DIR)/.unpacked-$(CBV2_TAG): $(SOURCE_DIR)/$(CBV2_TARBALL) | $(CBV2_STAMP_DIR) $(CBV2_LOG_DIR)
	@ rm -f $(CBV2_STAMP_DIR)/.unpacked*
	@ echo "Unpacking coreboot ($(CBV2_TARBALL))..."
	@ tar -C $(CBV2_DIR) -zxf $(SOURCE_DIR)/$(CBV2_TARBALL)
	@ touch $@	

$(CBV2_STAMP_DIR)/.patched: $(CBV2_STAMP_DIR)/.unpacked-$(CBV2_TAG)
	@ echo "Patching coreboot..."
	@ $(BIN_DIR)/doquilt.sh $(CBV2_SRC_DIR) $(CBV2_PATCHES)
	@ touch $@

$(CBV2_STAMP_DIR)/.configured-$(COREBOOT_BOARD): $(CBV2_STAMP_DIR)/.patched
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

$(SOURCE_DIR)/$(CBV2_TARBALL):
	@ echo "Fetching the coreboot rev $(CBV2_TAG) code..."
	@ mkdir -p $(SOURCE_DIR)/coreboot
	@ $(BIN_DIR)/fetchsvn.sh $(CBV2_URL) $(SOURCE_DIR)/coreboot \
	$(CBV2_TAG) $(SOURCE_DIR)/$(CBV2_TARBALL) \
	> $(CBV2_FETCH_LOG) 2>&1

$(OUTPUT_DIR)/$(TARGET_ROM): $(CBV2_COMPONENTS)
	@ mkdir -p $(OUTPUT_DIR)
	@ $(BIN_DIR)/construct-rom.sh $(PLATFORM_DOPAD) $(CBV2_COMPONENTS) > $@

generic-coreboot: $(OUTPUT_DIR)/$(TARGET_ROM)

generic-coreboot-clean:
	@ echo "Cleaning coreboot..."
	@ rm -f $(CBV2_STAMP_DIR)/.configured*
	@ rm -f $(CBV2_PAYLOAD_TARGET)
ifneq ($(wildcard $(CBV2_BUILD_DIR)/Makefile),)
	@ $(MAKE) -C $(CBV2_BUILD_DIR) clean > /dev/null 2>&1;
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

