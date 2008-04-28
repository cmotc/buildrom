# Build file for the AMD Geode Norwich LAB kernel

KERNEL_URL=http://kernel.org/pub/linux/kernel/v2.6/
KERNEL_SOURCE=linux-$(KERNEL_VERSION).tar.bz2
KERNEL_CONFIG=$(PACKAGE_DIR)/kernel/conf/defconfig-msm800sev

#TINY_DIR=$(PACKAGE_DIR)/kernel/patches/tiny
#KERNEL_PATCHES += $(shell ls $(TINY_DIR)/*.patch)


$(SOURCE_DIR)/$(KERNEL_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(KERNEL_URL)/$(KERNEL_SOURCE)

include $(PACKAGE_DIR)/kernel/kernel.inc

kernel: generic-kernel
kernel-clean: generic-kernel-clean
kernel-distclean: generic-kernel-distclean
