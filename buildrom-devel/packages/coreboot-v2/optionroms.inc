# Rules to download option roms from the coreboot option ROM(s)
# repository

OPTIONROMURL=http://coreboot.org/data/optionroms/

$(OUTPUT_DIR)/$(OPTIONROM_ID).license:
	@ mkdir -p $(OUTPUT_DIR)
	@ wget -P $(OUTPUT_DIR) $(OPTIONROMURL)/$(OPTIONROM_ID).license -O $@

$(SOURCE_DIR)/$(OPTIONROM_ID).rom: $(OUTPUT_DIR)/$(OPTIONROM_ID).license
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(OPTIONROMURL)/$(OPTIONROM_ID).rom -O $@
