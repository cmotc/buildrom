# This is the common code included by all the targets

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_VENDOR),)
$(error No LinuxBIOS vendor specified)
endif
ifeq ($(LINUXBIOS_BOARD),)
$(error No LinuxBIOS board specified)
endif
ifeq ($(LBV2_CONFIG),)
$(error No LinuxBIOS config specified)
endif
ifeq ($(LBV2_TDIR),)
$(error No LinuxBIOS TDIR specified)
endif
endif

LBV2_OUTPUT=$(LBV2_BUILD_DIR)/$(LBV2_ROM_NAME)
LBV2_DIR=$(BUILD_DIR)/linuxbios

# If the user wanted to override the build directory - obey that now

ifeq ($(CONFIG_LB_USE_BUILD),y)
LBV2_SRC_DIR=$(subst ",,$(CONFIG_LB_BUILDDIR))
else
LBV2_SRC_DIR=$(LBV2_DIR)/$(LBV2_BASE_DIR)
endif

LBV2_TARGET_DIR=$(LBV2_SRC_DIR)/targets/
LBV2_TARGET_NAME=$(LINUXBIOS_VENDOR)/$(LINUXBIOS_BOARD)
LBV2_CONFIG_NAME=$(LBV2_TARGET_NAME)/$(LBV2_CONFIG)

LBV2_BUILD_DIR=$(LBV2_TARGET_DIR)/$(LBV2_TARGET_NAME)/$(LBV2_TDIR)

LBV2_STAMP_DIR=$(LBV2_DIR)/stamps
LBV2_LOG_DIR=$(LBV2_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
LBV2_FETCH_LOG=/dev/stdout
LBV2_CONFIG_LOG=/dev/stdout
LBV2_BUILD_LOG=/dev/stdout
LBV2_INSTALL_LOG=/dev/stdout
else
LBV2_FETCH_LOG=$(LBV2_LOG_DIR)/fetch.log
LBV2_BUILD_LOG=$(LBV2_LOG_DIR)/build.log
LBV2_CONFIG_LOG=$(LBV2_LOG_DIR)/config.log
LBV2_INSTALL_LOG=$(LBV2_LOG_DIR)/install.log
endif

# This allows us to skip the unpack/patch/configure stage

ifeq ($(CONFIG_LB_USE_BUILD),y)
LBV2_DIR_TARGET=
else
LBV2_DIR_TARGET=$(LBV2_STAMP_DIR)/.configured
endif

$(LBV2_PAYLOAD_TARGET): $(PAYLOAD_TARGET)
	@ cp $< $@

$(LBV2_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LBV2_TARBALL)
	@ echo "Unpacking LinuxBIOS..."
	@ tar -C $(LBV2_DIR) -zxf $(SOURCE_DIR)/$(LBV2_TARBALL)
	@ touch $@	

$(LBV2_STAMP_DIR)/.patched: $(LBV2_STAMP_DIR)/.unpacked 
	@ echo "Patching LinuxBIOS..."
	@ $(BIN_DIR)/doquilt.sh $(LBV2_SRC_DIR) $(LBV2_PATCHES)
	@ touch $@

$(LBV2_STAMP_DIR)/.configured: $(LBV2_STAMP_DIR)/.patched
	@ echo "Building target..."
	@( cd $(LBV2_TARGET_DIR); \
	./buildtarget $(LBV2_CONFIG_NAME) > $(LBV2_CONFIG_LOG) 2>&1)
	@ touch $@

$(LBV2_STAMP_DIR) $(LBV2_LOG_DIR):
	@ mkdir -p $@

$(LBV2_OUTPUT): $(LBV2_STAMP_DIR) $(LBV2_LOG_DIR) $(LBV2_DIR_TARGET) $(LBV2_PAYLOAD_TARGET)
	@ echo "Building linuxbios..."
	@ (export CPU_OPT="$(STACKPROTECT)"; \
	make -C $(LBV2_BUILD_DIR) > $(LBV2_BUILD_LOG) 2>&1)

generic-linuxbios-clean:
	@ echo "Cleaning linuxbios..."
	@ rm -f $(LBV2_PAYLOAD_TARGET)
	@ if [ -d $(LBV2_BUILD_DIR) ];then \
	$(MAKE) -C $(LBV2_BUILD_DIR) clean > /dev/null 2>&1; \
	fi	
	@ rm -f $(LBV2_OUTPUT)

generic-linuxbios-distclean:
	@ if [ "$(CONFIG_LB_USE_BUILD)" = "y" ]; then \
	echo "Cleaning linuxbios build..."; \
	$(MAKE) -C $(LBV2_BUILD_DIR) clean > /dev/null 2>&1; \
	rm -f $(LBV2_OUTPUT); \
	fi	

	@ rm -rf $(LBV2_DIR)/*
