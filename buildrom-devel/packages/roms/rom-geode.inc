# This is the geode specific optionrom target
# download VSA

VSA_URL=http://www.amd.com/files/connectivitysolutions/geode/geode_lx/
GEODE_VSA=lx_vsa.36k.bin

$(SOURCE_DIR)/$(GEODE_VSA):
	@ echo "Fetching the VSA code..."
	@ wget $(wGET_Q) -P $(SOURCE_DIR) $(VSA_URL)/$(GEODE_VSA).gz -O $@

# Copy the file to the ROM_DIR - it should have the same name that it
# will have in the LAR

$(ROM_DIR)/vsa: $(SOURCE_DIR)/$(GEODE_VSA):
	@ cp $< $@

OPTIONROM_TARGETS += $(ROM_DIR)/vsa
