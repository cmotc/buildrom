# LinuxBIOS build script

ifeq ($(LINUXBIOS_VENDOR),)
LINUXBIOS_VENDOR=olpc
endif
ifeq ($(LINUXBIOS_BOARD),)
LINUXBIOS_BOARD=rev_a
endif
ifeq ($(LINUXBIOS_CONFIG),)
LINUXBIOS_CONFIG=Config.SPI.lb
endif
ifeq ($(LINUXBIOS_TDIR),)
LINUXBIOS_TDIR=rev_a_1M
endif
ifeq ($(LINUXBIOS_FETCH),)
LINUXBIOS_FETCH=git
endif

LINUXBIOS_PATCHES =

ifeq ($(PAYLOAD_LAB),y)
LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/dcon-detect.patch
endif

ifeq ($(LINUXBIOS_ENABLE_LZMA),y)
LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/lzma-config.patch
endif

ifeq ($(LINUXBIOS_CAS25),y)
LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/CL2.5.patch
LINUXBIOS_CL2_MARKER=_CL2.5
endif

EC_FIRMWARE_URL=http://dev.laptop.org/pub/ec

ifeq ($(EC_FIRMWARE_OVERRIDE),)
EC_FIRMWARE_REV=ec_v$(EC_VER).img
else
EC_FIRMWARE_REV=$(EC_FIRMWARE_OVERRIDE)
endif

LINUXBIOS_ROM_FILENAME=olpc-$(FIRMWARE_REVISION)$(LINUXBIOS_CL2_MARKER).rom

LINUXBIOS_DIR=$(BUILD_DIR)/linuxbios

LINUXBIOS_TARGET_DIR=$(LINUXBIOS_SRC_DIR)/targets/
LINUXBIOS_TARGET_NAME=$(LINUXBIOS_VENDOR)/$(LINUXBIOS_BOARD)
LINUXBIOS_CONFIG_NAME=$(LINUXBIOS_TARGET_NAME)/$(LINUXBIOS_CONFIG)
LINUXBIOS_BUILD_DIR=$(LINUXBIOS_TARGET_DIR)/$(LINUXBIOS_TARGET_NAME)/$(LINUXBIOS_TDIR)

# Choose the right variables to use based on our fetch method

ifeq ($(LINUXBIOS_FETCH),git)
LINUXBIOS_FETCHSH=$(BIN_DIR)/fetchgit.sh
LINUXBIOS_SRC_DIR=$(LINUXBIOS_DIR)/git
LINUXBIOS_TAG=$(LINUXBIOS_GIT_TAG)
LINUXBIOS_URL=$(LINUXBIOS_GIT_URL)
else
LINUXBIOS_FETCHSH=$(BIN_DIR)/fetchsvn.sh
LINUXBIOS_SRC_DIR=$(LINUXBIOS_DIR)/svn
LINUXBIOS_TAG=$(LINUXBIOS_SVN_TAG)
LINUXBIOS_URL=$(LINUXBIOS_SVN_URL)
endif

ifeq ($(LINUXBIOS_TAG),)
$(error LINUXBIOS_TAG was not defined.  Check your Config.mk)
endif

ifeq ($(LINUXBIOS_URL),)
$(error LINUXBIOS_URL was not defined.  Check your Config.mk)
endif

LINUXBIOS_TARBALL=linuxbios-$(LINUXBIOS_FETCH)-$(LINUXBIOS_TAG).tar.gz

LINUXBIOS_STAMP_DIR=$(LINUXBIOS_DIR)/stamps
LINUXBIOS_LOG_DIR=$(LINUXBIOS_DIR)/logs

ifeq ($(VERBOSE),y)
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

# Build the manufacturer string from the firmware model and revision

FIRMWARE_REV2 = $(shell echo $(FIRMWARE_REVISION) | awk '{print substr($$1,0,3)}')
MANUFACTURER_STRING = `printf "%-6s%-7s%-3s" $(FIRMWARE_MODEL) $(FIRMWARE_REVISION) $(FIRMWARE_REV2)`

# fix me sooner or later!
/tmp/olpcpayload.elf: $(PAYLOAD_TARGET)
	@ cp $< $@

$(SOURCE_DIR)/$(LINUXBIOS_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(LINUXBIOS_FETCHSH) $(LINUXBIOS_URL) $(SOURCE_DIR)/linuxbios \
	$(LINUXBIOS_TAG) $(SOURCE_DIR)/$(LINUXBIOS_TARBALL) \
	> $(LINUXBIOS_FETCH_LOG) 2>&1

$(LINUXBIOS_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LINUXBIOS_TARBALL)
	@ echo "Unpacking LinuxBIOS..."
	@ tar -C $(LINUXBIOS_DIR) -zxf $(SOURCE_DIR)/$(LINUXBIOS_TARBALL)
	@ touch $@	

$(LINUXBIOS_STAMP_DIR)/.patched: $(LINUXBIOS_STAMP_DIR)/.unpacked
	@ echo "Patching LinuxBIOS..."
	@ $(BIN_DIR)/doquilt.sh $(LINUXBIOS_SRC_DIR) $(LINUXBIOS_PATCHES)
	@ touch $@

$(LINUXBIOS_STAMP_DIR)/.configured: $(LINUXBIOS_STAMP_DIR)/.patched
	@ echo "Building target config file..."
	@( cd $(LINUXBIOS_TARGET_DIR); \
	./buildtarget $(LINUXBIOS_CONFIG_NAME) > $(LINUXBIOS_CONFIG_LOG) 2>&1)
	@ touch $@

ifeq ($(EC_FIRMWARE_OVERRIDE),)
$(LINUXBIOS_STAMP_DIR)/.pull_ecf_$(EC_FIRMWARE_REV):
	@ echo "Fetching the EC bits..."
	@ wget -N -P $(LINUXBIOS_BUILD_DIR) $(EC_FIRMWARE_URL)/$(EC_FIRMWARE_REV) 
	@ wget -N -P $(LINUXBIOS_BUILD_DIR) $(EC_FIRMWARE_URL)/MD5SUMS 
	@ if [ "`md5sum $(LINUXBIOS_BUILD_DIR)/$(EC_FIRMWARE_REV) |cut -d' ' -f1`" != "`grep $(EC_FIRMWARE_REV) $(LINUXBIOS_BUILD_DIR)/MD5SUMS | cut -d' ' -f1`" ]; then echo "ERROR! EC firmware hash does not match"; exit 1; fi
	@ echo "EC Bits fetched and verified"
	@ touch $@
else
$(LINUXBIOS_STAMP_DIR)/.pull_ecf_$(EC_FIRMWARE_REV):
	@ echo "EC_FIRMWARE_OVERRIDE active so using custom EC bits from $(EC_FIRMWARE_OVERRIDE)"
	@ cp -f $(PACKAGE_DIR)/bin/$(EC_FIRMWARE_OVERRIDE) $(LINUXBIOS_BUILD_DIR)/$(EC_FIRMWARE_REV)	
	@ touch $@
endif

$(LINUXBIOS_BUILD_DIR)/$(LINUXBIOS_ROM_FILENAME):  $(LINUXBIOS_STAMP_DIR)/.configured /tmp/olpcpayload.elf
	@ echo "Building linuxbios..."
	@ make -C $(LINUXBIOS_BUILD_DIR) > $(LINUXBIOS_BUILD_LOG) 2>&1

$(LINUXBIOS_BUILD_DIR)/$(LINUXBIOS_ROM_FILENAME).nosig: $(LINUXBIOS_BUILD_DIR)/$(LINUXBIOS_ROM_FILENAME) $(LINUXBIOS_STAMP_DIR)/.pull_ecf_$(EC_FIRMWARE_REV)
	@ echo "Creating FIRMWARE_REVISON = $(FIRMWARE_REVISION) ROM and md5 files" 
	@ cat $(LINUXBIOS_BUILD_DIR)/$(EC_FIRMWARE_REV) $(PACKAGE_DIR)/bin/olpc_vsa.64k.bin $(LINUXBIOS_BUILD_DIR)/linuxbios.rom > $@

$(OUTPUT_DIR)/$(LINUXBIOS_ROM_FILENAME): $(LINUXBIOS_BUILD_DIR)/$(LINUXBIOS_ROM_FILENAME).nosig
	@ $(BIN_DIR)/setsig.sh $< "$(MANUFACTURER_STRING)" $@ 
	@ $(STAGING_DIR)/bin/crc32sum -a $@ > $(LINUXBIOS_BUILD_LOG)
	@ md5sum $@ | cut -d ' ' -f 1 > $(OUTPUT_DIR)/$(LINUXBIOS_ROM_FILENAME).md5
	
$(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR):
	@ mkdir -p $@

linuxbios: $(LINUXBIOS_STAMP_DIR) $(LINUXBIOS_LOG_DIR) $(OUTPUT_DIR)/$(LINUXBIOS_ROM_FILENAME)

linuxbios-clean:
	@ echo "Cleaning linuxbios..."
	@ $(MAKE) -C $(LINUXBIOS_BUILD_DIR) clean > /dev/null 2>&1
	@ rm -f $(LINUXBIOS_STAMP_DIR)/.pull_ecf_$(EC_FIRMWARE_REV)
	@ rm -f $(LINUXBIOS_BUILD_DIR)/$(EC_FIRMWARE_REV) \
	$(LINUXBIOS_BUILD_DIR)/MD5SUMS

linuxbios-distclean:
	@ rm -rf $(LINUXBIOS_DIR)/*

linuxbios-bom:
	@ echo "Package: linuxbios"
	@ echo "Source:  $(LINUXBIOS_URL)"
	@ echo "Revison: $(LINUXBIOS_TAG)"
	@ echo "Tarball: `basename $(LINUXBIOS_TARBALL)"
	@ echo ""

