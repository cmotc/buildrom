# This is the Generic coreboot target

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

coreboot: generic-coreboot
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
