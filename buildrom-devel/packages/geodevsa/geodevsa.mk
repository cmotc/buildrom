# Master targets for VSA manipulation

GEODE_UNCOMPRESSED_VSA=$(OUTPUT_DIR)/vsa/geodevsa.bin
GEODE_COMPRESSED_VSA=$(OUTPUT_DIR)/vsa/geodevsa.bin.nrv
GEODE_PADDED_VSA=$(OUTPUT_DIR)/vsa/geodevsa.bin.nrv.pad

GEODE_VSA_SIZE=36864

ifeq ($(CONFIG_COREBOOT_V2),y)
VSA_BUILD_TARGET = $(GEODE_PADDED_VSA)
else
VSA_BUILD_TARGET = $(GEODE_UNCOMPRESSED_VSA)
endif

ifeq ($(CONFIG_COREBOOT_V3),y)
VSA_ROM_FILE = $(ROM_DIR)/blob/vsa
endif

VSA_CLEAN_TARGET=
VSA_DISTCLEAN_TARGET=

ifeq ($(CONFIG_VSA_LEGACY),y)
include $(PACKAGE_DIR)/geodevsa/amdvsa.inc
else
include $(PACKAGE_DIR)/geodevsa/openvsa.inc

VSA_CLEAN_TARGET=openvsa-clean
VSA_DISTCLEAN_TARGET=openvsa-distclean
endif

$(GEODE_COMPRESSED_VSA): $(GEODE_UNCOMPRESSED_VSA)
	@ $(STAGING_DIR)/bin/nrv2b e $(GEODE_UNCOMPRESSED_VSA) $@ \
	> /dev/null 2>&1

$(GEODE_PADDED_VSA): $(GEODE_COMPRESSED_VSA)
	@ cp $< $@
	@ (size=`stat -c %s $<`; count=`expr $(GEODE_VSA_SIZE) - $$size`; \
	  dd if=/dev/zero bs=1 count=$$count  >> $@ 2> /dev/null)

ifeq ($(CONFIG_COREBOOT_V3),y)
$(VSA_ROM_FILE): $(VSA_BUILD_TARGET)
	mkdir -p $(shell dirname $(VSA_ROM_FILE))
	cp $(VSA_BUILD_TARGET) $(VSA_ROM_FILE)
endif

geodevsa: $(VSA_BUILD_TARGET) $(VSA_ROM_FILE)

geodevsa-clean: $(VSA_CLEAN_TARGET)
	@ rm -f $(GEODE_UNCOMPRESSED_VSA) $(GEODE_COMPRESSED_VSA)
	@ rm -f $(GEODE_PADDED_VSA) $(VSA_ROM_FILE)

geodevsa-distclean: $(VSA_DISTCLEAN_TARGET)
	@ rm -rf $(OUTPUT_DIR)/vsa $(VSA_ROM_FILE)
