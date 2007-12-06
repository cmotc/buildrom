# This is the common code included by all the targets

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_VENDOR),)
$(error No LinuxBIOS vendor specified)
endif
ifeq ($(LINUXBIOS_BOARD),)
$(error No LinuxBIOS board specified)
endif
ifeq ($(CONFIG_LINUXBIOS_V3),y)
  ifeq ($(LINUXBIOS_V3_CONFIG),)
  $(error No LinuxBIOSv3 config specified)
  endif
else
  ifeq ($(LINUXBIOS_CONFIG),)
  $(error No LinuxBIOS config specified)
  endif
endif
ifeq ($(LINUXBIOS_TDIR),)
$(error No LinuxBIOS TDIR specified)
endif
endif

LINUXBIOS_OUTPUT=$(LINUXBIOS_BUILD_DIR)/$(LINUXBIOS_ROM_NAME)
LINUXBIOS_DIR=$(BUILD_DIR)/linuxbios

# If the user wanted to override the build directory - obey that now

ifeq ($(CONFIG_LB_USE_BUILD),y)
LINUXBIOS_SRC_DIR=$(subst ",,$(CONFIG_LB_BUILDDIR))
else
LINUXBIOS_SRC_DIR=$(LINUXBIOS_DIR)/$(LINUXBIOS_BASE_DIR)
endif

LINUXBIOS_TARGET_DIR=$(LINUXBIOS_SRC_DIR)/targets/
LINUXBIOS_TARGET_NAME=$(LINUXBIOS_VENDOR)/$(LINUXBIOS_BOARD)
LINUXBIOS_CONFIG_NAME=$(LINUXBIOS_TARGET_NAME)/$(LINUXBIOS_CONFIG)

ifeq ($(CONFIG_LINUXBIOS_V3),y)
LINUXBIOS_BUILD_DIR=$(LINUXBIOS_SRC_DIR)
else
LINUXBIOS_BUILD_DIR=$(LINUXBIOS_TARGET_DIR)/$(LINUXBIOS_TARGET_NAME)/$(LINUXBIOS_TDIR)
endif

LINUXBIOS_STAMP_DIR=$(LINUXBIOS_DIR)/stamps
LINUXBIOS_LOG_DIR=$(LINUXBIOS_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
LINUXBIOS_FETCH_LOG=/dev/stdout
LINUXBIOS_CONFIG_LOG=/dev/stdout
LINUXBIOS_BUILD_LOG=/dev/stdout
LINUXBIOS_INSTALL_LOG=/dev/stdout
else
LINUXBIOS_FETCH_LOG=$(LINUXBIOS_LOG_DIR)/fetch.log
LINUXBIOS_BUILD_LOG=$(LINUXBIOS_LOG_DIR)/build.log
LINUXBIOS_CONFIG_LOG=$(LINUXBIOS_LOG_DIR)/config.log
LINUXBIOS_INSTALL_LOG=$(LINUXBIOS_LOG_DIR)/install.log
endif

# This allows us to skip the unpack/patch/configure stage

ifeq ($(CONFIG_LB_USE_BUILD),y)
LINUXBIOS_DIR_TARGET=
else
LINUXBIOS_DIR_TARGET=$(LINUXBIOS_STAMP_DIR)/.configured
endif

$(LINUXBIOS_PAYLOAD_TARGET): $(PAYLOAD_TARGET)
	@ cp $< $@

$(LINUXBIOS_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LINUXBIOS_TARBALL)
	@ echo "Unpacking LinuxBIOS..."
	@ tar -C $(LINUXBIOS_DIR) -zxf $(SOURCE_DIR)/$(LINUXBIOS_TARBALL)
	@ touch $@	

$(LINUXBIOS_STAMP_DIR)/.patched: $(LINUXBIOS_STAMP_DIR)/.unpacked 
	@ echo "Patching LinuxBIOS..."
	@ $(BIN_DIR)/doquilt.sh $(LINUXBIOS_SRC_DIR) $(LINUXBIOS_PATCHES)
	@ touch $@

$(LINUXBIOS_STAMP_DIR)/.configured: $(LINUXBIOS_STAMP_DIR)/.patched
ifeq ($(CONFIG_LINUXBIOS_V3),y)
	@ echo "Configuring v3..."
	@ cp $(LINUXBIOS_V3_CONFIG) $(LINUXBIOS_SRC_DIR)/.config
	@ make -C $(LINUXBIOS_SRC_DIR) oldconfig > $(LINUXBIOS_CONFIG_LOG) 2>&1
	@ touch $@
else
	@ echo "Building target..."
	@( cd $(LINUXBIOS_TARGET_DIR); \
	./buildtarget $(LINUXBIOS_CONFIG_NAME) > $(LINUXBIOS_CONFIG_LOG) 2>&1)
	@ touch $@
endif

$(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR):
	@ mkdir -p $@

$(LINUXBIOS_OUTPUT): $(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR) $(LINUXBIOS_DIR_TARGET) $(LINUXBIOS_PAYLOAD_TARGET)
	@ echo "Building linuxbios..."
	@ (export CPU_OPT="$(STACKPROTECT)"; \
	make -C $(LINUXBIOS_BUILD_DIR) > $(LINUXBIOS_BUILD_LOG) 2>&1)

generic-linuxbios-clean:
	@ echo "Cleaning linuxbios..."
	@ rm -f $(LINUXBIOS_PAYLOAD_TARGET)
	@ if [ -d $(LINUXBIOS_BUILD_DIR) ];then \
	$(MAKE) -C $(LINUXBIOS_BUILD_DIR) clean > /dev/null 2>&1; \
	fi	
	@ rm -f $(LINUXBIOS_OUTPUT)

generic-linuxbios-distclean:
	@ if [ "$(CONFIG_LB_USE_BUILD)" = "y" ]; then \
	echo "Cleaning linuxbios build..."; \
	$(MAKE) -C $(LINUXBIOS_BUILD_DIR) clean > /dev/null 2>&1; \
	rm -f $(LINUXBIOS_OUTPUT); \
	fi	

	@ rm -rf $(LINUXBIOS_DIR)/*
