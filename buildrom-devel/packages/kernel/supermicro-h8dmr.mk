# Build file for the Supermicro H8DMR LAB kernel

KERNEL_URL=http://kernel.org/pub/linux/kernel/v2.6/
KERNEL_SOURCE=linux-$(KERNEL_VERSION).tar.bz2

# KERNEL_CONFIG is defined in the platform configuration

TINY_URL=http://elinux.org/images/0/0e/
TINY_SOURCE=Tiny-quilt-2.6.22.1-1.tar.gz
TINY_DIR=$(KERNEL_DIR)/tiny/patches

KERNEL_PATCHES += $(TINY_DIR)

$(SOURCE_DIR)/$(KERNEL_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(KERNEL_URL)/$(KERNEL_SOURCE)

$(SOURCE_DIR)/$(TINY_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(TINY_URL)/$(TINY_SOURCE)

include $(PACKAGE_DIR)/kernel/kernel.inc

kernel: generic-kernel
kernel-clean: generic-kernel-clean
kernel-distclean: generic-kernel-distclean
