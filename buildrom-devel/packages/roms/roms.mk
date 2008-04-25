# Each platform that needs an option ROM or other binary blob is specified
# here

OPTIONROM_TARGETS?=

OPTIONROM-y =
OPTIONROM-$(CONFIG_PLATFORM_NORWICH) += rom-geode.inc

ifneq ($(OPTIONROMS-y),)
include $(OPTIONROM-y)
endif

$(ROM_DIR):
	@ mkdir -p $(ROM_DIR)

roms: $(ROM_DIR) $(OPTIONROM_TARGETS)

roms-clean:
ifneq ($(OPTIONROM_TARGETS),)
	@ rm -rf $(OPTIONROM_TARGETS)
endif

roms-distclean: roms-clean
