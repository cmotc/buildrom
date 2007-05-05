# This is the OLPC LinuxBIOS target

ifeq ($(CONFIG_PLATFORM),y)
ifeq ($(LINUXBIOS_TAG),)
$(error You need to specify a version to pull in your platform config)
endif
endif

TARGET_ROM=olpc-$(FIRMWARE_REVISION)$(LINUXBIOS_CL2_MARKER).rom
LINUXBIOS_FETCHSH=$(BIN_DIR)/fetchgit.sh
LINUXBIOS_BASE_DIR=git
LINUXBIOS_URL=git://dev.laptop.org/projects/linuxbios
LINUXBIOS_TARBALL=linuxbios-git-$(LINUXBIOS_TAG).tar.gz
LINUXBIOS_PAYLOAD_TARGET = /tmp/olpcpayload.elf
LINUXBIOS_VSA=$(PACKAGE_DIR)/bin/olpc_vsa.64k.bin

MANUFACTURER_STRING = `printf "%-6s%-7s%-3s" $(FIRMWARE_MODEL) $(FIRMWARE_REVISION) $(FIRMWARE_REV2)`

ifeq ($(CONFIG_USE_LZMA),y)
LINUXBIOS_PATCHES += $(PACKAGE_DIR)/linuxbios/patches/lzma-config.patch
endif

include $(PACKAGE_DIR)/linuxbios/linuxbios.inc

$(SOURCE_DIR)/$(LINUXBIOS_TARBALL): 
	@ echo "Fetching the LinuxBIOS code..."
	@ mkdir -p $(SOURCE_DIR)/linuxbios
	@ $(BIN_DIR)/fetchgit.sh $(LINUXBIOS_URL) $(SOURCE_DIR)/linuxbios \
	$(LINUXBIOS_TAG) $(SOURCE_DIR)/$(LINUXBIOS_TARBALL) \
	> $(LINUXBIOS_FETCH_LOG) 2>&1

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


$(OUTPUT_DIR)/$(OLPC_ROM_FILENAME).nosig: $(LINUXBIOS_OUTPUT) $(LINUXBIOS_STAMP_DIR)/.pull_ecf_$(EC_FIRMWARE_REV)
	@ echo "Creating FIRMWARE_REVISON = $(FIRMWARE_REVISION) ROM and md5 files"
	@ cat $(LINUXBIOS_BUILD_DIR)/$(EC_FIRMWARE_REV) $(LINUXBIOS_VSA) \
	$(LINUXBIOS_BUILD_DIR)/$(LINUXBIOS_OUTPUT) > $@

$(TARGET_ROM): $(OUTPUT_DIR)/$(OLPC_ROM_FILENAME).nosig
	@ $(BIN_DIR)/setsig.sh $< "$(MANUFACTURER_STRING)" $@ 
	@ $(STAGING_DIR)/bin/crc32sum -a $@ > $(LINUXBIOS_BUILD_LOG)
	@ md5sum $@ | cut -d ' ' -f 1 > $(OUTPUT_DIR)/$(LINUXBIOS_ROM_FILENAME).md5

linuxbios: $(OUTPUT_DIR)/$(TARGET_ROM)
linuxbios-clean: generic-linuxbios-clean
	@ rm -f $(LINUXBIOS_STAMP_DIR)/.pull_ecf_$(EC_FIRMWARE_REV)
	@ rm -f $(LINUXBIOS_BUILD_DIR)/$(EC_FIRMWARE_REV) \
        $(LINUXBIOS_BUILD_DIR)/MD5SUMS

linuxbios-distclean: generic-linuxbios-distclean

