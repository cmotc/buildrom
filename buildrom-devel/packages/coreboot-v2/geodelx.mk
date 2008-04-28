# This target supports all Geode LX platforms

CBV2_PREPEND=$(GEODE_PADDED_VSA)

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

coreboot: geodevsa generic-coreboot
coreboot-clean: geodevsa-clean generic-coreboot-clean
coreboot-distclean: geodevsa-distclean generic-coreboot-distclean
