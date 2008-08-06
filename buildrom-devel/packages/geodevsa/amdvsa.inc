# Target file for the AMD VSA binary - included from geodevsa.mk

AMDVSA_URL=http://www.amd.com/files/connectivitysolutions/geode/geode_lx
AMDVSA_BIN=amd_vsa_lx_1.01.bin

# 2008-02-19 - the AMD URL above is broken, when trying to wget
# amd_vsa_lx_1.01.bin.gz it arrives uncompressed instead.  This
# breakage is expected to be fixed; but to properly
# handle this temporary situation without breakage down the line,
# we do the unsual check of the file type below:
# Jordan

$(SOURCE_DIR)/$(AMDVSA_BIN):
	@ mkdir -p $(SOURCE_DIR)
	@ echo "Fetching the AMD VSA binary..."
	wget $(WGET_Q) -P $(SOURCE_DIR) $(AMDVSA_URL)/$(AMDVSA_BIN).gz -O $@.gz
	@ if file $@.gz | grep -q "gzip"; then \
	gunzip -q $@.gz; else mv $@.gz $@; fi

$(GEODE_UNCOMPRESSED_VSA): $(SOURCE_DIR)/$(AMDVSA_BIN)
	@ mkdir -p $(shell dirname $(GEODE_UNCOMPRESSED_VSA))
	@ cp $< $@
