# LinuxBIOS build script

ifeq ($(LINUXBIOS_VENDOR),)
LINUXBIOS_VENDOR=olpc
endif
ifeq ($(LINUXBIOS_BOARD),)
LINUXBIOS_BOARD=rev_a
endif
ifeq ($(LINUXBIOS_CONFIG),)
LINUXBIOS_CONFIG=Config.1M.lb
endif
ifeq ($(LINUXBIOS_TDIR),)
LINUXBIOS_TDIR=rev_a_1M
endif

LINUXBIOS_SOURCE_DIR=LinuxBIOSv2
LINUXBIOS_SVN=svn://openbios.org/repos/trunk/LinuxBIOSv2
LINUXBIOS_DIR=$(BUILD_DIR)/linuxbios
LINUXBIOS_SRC_DIR=$(LINUXBIOS_DIR)/$(LINUXBIOS_SOURCE_DIR)
LINUXBIOS_TARGET_DIR=$(LINUXBIOS_SRC_DIR)/targets/
LINUXBIOS_TARGET_NAME=$(LINUXBIOS_VENDOR)/$(LINUXBIOS_BOARD)
LINUXBIOS_CONFIG_NAME=$(LINUXBIOS_TARGET_NAME)/$(LINUXBIOS_CONFIG)
LINUXBIOS_BUILD_DIR=$(LINUXBIOS_TARGET_DIR)/$(LINUXBIOS_TARGET_NAME)/$(LINUXBIOS_TDIR)
LINUXBIOS_STAMP_DIR=$(LINUXBIOS_DIR)/stamps
LINUXBIOS_LOG_DIR=$(LINUXBIOS_DIR)/logs
LINUXBIOS_VER=2348

ifeq ($(VERBOSE),y)
LINUXBIOS_FETCH_LOG=/dev/stdout
LINUXBIOS_CONFIG_LOG=/dev/stdout
LINUXBIOS_BUILD_LOG=/dev/stdout
LINUXBIOS_INSTALL_LOG=/dev/stdout
NRV2B_BUILD_LOG=/dev/stdout
else
LINUXBIOS_FETCH_LOG=$(LINUXBIOS_LOG_DIR)/fetch.log
LINUXBIOS_BUILD_LOG=$(LINUXBIOS_LOG_DIR)/build.log
LINUXBIOS_CONFIG_LOG=$(LINUXBIOS_LOG_DIR)/config.log
LINUXBIOS_INSTALL_LOG=$(LINUXBIOS_LOG_DIR)/install.log
NRV2B_BUILD_LOG=$(LINUXBIOS_LOG_DIR)/nrv2b.build.log
endif

$(LINUXBIOS_STAMP_DIR)/.unpacked_$(LINUXBIOS_VER): 
	@ echo "Checking Linuxbios repository..."
	@ $(BIN_DIR)/fetchsvn.sh $(LINUXBIOS_SVN) $(LINUXBIOS_SRC_DIR) \
	$(LINUXBIOS_VER) > $(LINUXBIOS_FETCH_LOG) 2>&1
	@ touch $@

# fix me sooner or later!
/tmp/olpcpayload.elf: $(PAYLOAD_TARGET)
	@ cp $< $@

$(LINUXBIOS_STAMP_DIR)/.configured: $(LINUXBIOS_STAMP_DIR)/.unpacked_$(LINUXBIOS_VER)
	@( cd $(LINUXBIOS_TARGET_DIR); \
	./buildtarget $(LINUXBIOS_CONFIG_NAME) > $(LINUXBIOS_CONFIG_LOG) 2>&1)
	@ touch $@

$(LINUXBIOS_BUILD_DIR)/linuxbios.rom:  $(LINUXBIOS_STAMP_DIR)/.configured /tmp/olpcpayload.elf
	@ echo "Building linuxbios..."
	@ make -C $(LINUXBIOS_BUILD_DIR) > $(LINUXBIOS_BUILD_LOG) 2>&1

$(OUTPUT_DIR)/linuxbios.rom:  $(LINUXBIOS_BUILD_DIR)/linuxbios.rom
	@ echo "Making the ROM..."
	@ cat $(PACKAGE_DIR)/vsa/olpc_vsa.64k.bin \
	$(LINUXBIOS_BUILD_DIR)/linuxbios.rom > $@

$(LINUXBIOS_SRC_DIR)/util/nrv2b/nrv2b: $(LINUXBIOS_STAMP_DIR)/.unpacked_$(LINUXBIOS_VER)
	@ echo "Building nrv2b..."
	@ make -C $(LINUXBIOS_SRC_DIR)/util/nrv2b CFLAGS="$(HOST_CFLAGS)" \
	LDFLAGS=$(HOST_LDFLAGS) > $(NRV2B_BUILD_LOG) 2>&1

$(STAGING_DIR)/bin/nrv2b: $(LINUXBIOS_SRC_DIR)/util/nrv2b/nrv2b
	@ install -d $(STAGING_DIR)/bin
	@ install -m 0755 $< $@

$(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR):
	@ mkdir -p $@

linuxbios: $(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR) $(OUTPUT_DIR)/linuxbios.rom

nrv2b: $(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR) $(STAGING_DIR)/bin/nrv2b

linuxbios-clean:
	@ echo "Cleaning linuxbios..."
	@ $(MAKE) -C $(LINUXBIOS_BUILD_DIR) clean > /dev/null 2>&1

linuxbios-distclean:
	@ rm -rf $(LINUXBIOS_DIR)/*
