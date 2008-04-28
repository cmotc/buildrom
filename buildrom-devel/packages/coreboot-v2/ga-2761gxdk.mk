
CBV2_PATCHES=

# This matches the base name of the ROM on
# http://www.coreboot.org/data/optionroms/

OPTIONROM_ID=pci1039,6330

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

coreboot: generic-coreboot
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
