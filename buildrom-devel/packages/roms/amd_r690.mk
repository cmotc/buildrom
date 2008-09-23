ifeq ($(CONFIG_AMD_R690_USE_VBIOS),y)
R690_TARGET_ROM := $(shell basename $(AMD_R690_VBIOS_LOCATION))
OPTIONROM_TARGETS += $(OUTPUT_DIR)/roms/$(R690_TARGET_ROM)
CBV2_PREPEND := $(OUTPUT_DIR)/roms/$(R690_TARGET_ROM)
endif

$(AMD_R690_VBIOS_LOCATION):
	@ $(BIN_DIR)/show-instructions.sh \
	$(PACKAGE_DIR)/roms/amd_r690_instructions \
	$(AMD_R690_VBIOS_LOCATION)
	@ echo "Unable to find $(AMD_R690_VBIOS_LOCATION)"
	@ exit 1

$(OUTPUT_DIR)/roms/$(R690_TARGET_ROM): $(AMD_R690_VBIOS_LOCATION)
	@ mkdir -p $(OUTPUT_DIR)/roms
	@ cp $< $@
