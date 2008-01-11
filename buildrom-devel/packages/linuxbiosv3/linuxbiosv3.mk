ifeq ($(LBV3_TAG),)
$(error You need to specify a version to pull in your platform config)
endif

LBV3_URL=svn://openbios.org/repository/LinuxBIOSv3
LBV3_TARBALL=linuxbios-svn-$(LBV3_TAG).tar.gz
LBV3_DIR=$(BUILD_DIR)/linuxbiosv3
LBV3_SRC_DIR=$(LBV3_DIR)/svn

LBV3_STAMP_DIR=$(LBV3_DIR)/stamps
LBV3_LOG_DIR=$(LBV3_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
LBV3_FETCH_LOG=/dev/stdout
LBV3_CONFIG_LOG=/dev/stdout
LBV3_BUILD_LOG=/dev/stdout
else
LBV3_FETCH_LOG=$(LBV3_LOG_DIR)/fetch.log
LBV3_CONFIG_LOG=$(LBV3_LOG_DIR)/config.log
LBV3_BUILD_LOG=$(LBV3_LOG_DIR)/build.log
endif

TARGET_ROM = $(LINUXBIOS_VENDOR)-$(LINUXBIOS_BOARD).rom

LBV3_OUTPUT=$(LBV3_SRC_DIR)/build/linuxbios.rom

LBV3_PATCHES ?=

$(SOURCE_DIR)/$(LBV3_TARBALL):
	@ mkdir -p $(SOURCE_DIR)/linuxbiosv3
	@ $(BIN_DIR)/fetchsvn.sh $(LBV3_URL) \
	$(SOURCE_DIR)/linuxbiosv3 $(LBV3_TAG) \
	$@ > $(LBV3_FETCH_LOG) 2>&1

$(LBV3_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LBV3_TARBALL)
	@echo "Unpacking LinuxBIOSv3..."
	@ mkdir -p $(LBV3_DIR)
	@ tar -C $(LBV3_DIR) -zxf $(SOURCE_DIR)/$(LBV3_TARBALL)
	@ touch $@

$(LBV3_STAMP_DIR)/.patched: $(LBV3_STAMP_DIR)/.unpacked
	@ echo "Patching LinuxBIOSv3..."
	@ $(BIN_DIR)/doquilt.sh $(LBV3_SRC_DIR) $(LBV3_PATCHES)
	@ touch $@

$(LBV3_STAMP_DIR)/.configured: $(LBV3_STAMP_DIR)/.patched
	@ echo "Configuring LinuxBIOSv3..."
	@ cp $(PACKAGE_DIR)/linuxbiosv3/conf/$(LBV3_CONFIG) $(LBV3_SRC_DIR)/.config
	@ make -C $(LBV3_SRC_DIR) oldconfig > $(LBV3_CONFIG_LOG) 2>&1
	@ touch $@

$(LBV3_OUTPUT): $(LBV3_STAMP_DIR)/.configured
	@ echo "Building LinuxBIOSv3..."
	@ $(MAKE) -C $(LBV3_SRC_DIR) > $(LBV3_BUILD_LOG) 2>&1

$(LBV3_SRC_DIR)/build/util/lar/lar: $(LBV3_STAMP_DIR)/.configured
	@ $(MAKE) -C $(LBV3_SRC_DIR)/util lar > $(LBV3_BUILD_LOG) 2>&1

$(STAGING_DIR)/bin/lar: $(LBV3_SRC_DIR)/build/util/lar/lar
	@ mkdir -p $(STAGING_DIR)/bin
	@ cp $< $@


$(LBV3_STAMP_DIR) $(LBV3_LOG_DIR):
	@ mkdir -p $@

linuxbiosv3: $(LBV3_LOG_DIR) $(LBV3_STAMP_DIR) $(LBV3_OUTPUT) $(STAGING_DIR)/bin/lar

linuxbiosv3-clean:
	@ echo "Cleaning linuxbiosv3..."
	@ $(MAKE) -C $(LBV3_SRC_DIR) clean > /dev/null 2>&1

linuxbiosv3-distclean:
	@ rm -rf $(LBV3_DIR)/*
	@ rm -rf $(STAGING_DIR)/bin/lar

