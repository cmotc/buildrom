# Each platform that needs an option ROM or other binary blob is specified
# here

OPTIONROM_TARGETS ?=

OPTIONROMS-y =
OPTIONROMS-$(CONFIG_PLATFORM_DBM690T) += $(PACKAGE_DIR)/roms/amd_r690.mk

ifneq ($(OPTIONROMS-y),)
include $(OPTIONROMS-y)
endif

$(ROM_DIR):
	@ mkdir -p $(ROM_DIR)

roms: $(ROM_DIR) $(OPTIONROM_TARGETS)

roms-clean:

roms-distclean:
