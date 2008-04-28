# Build file for the AMD Serengeti_Cheetah LAB kernel

KERNEL_URL=http://kernel.org/pub/linux/kernel/v2.6/
KERNEL_SOURCE=linux-$(KERNEL_VERSION).tar.bz2

# Kernel config is set in the platform configuration

$(SOURCE_DIR)/$(KERNEL_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(KERNEL_URL)/$(KERNEL_SOURCE)

include $(PACKAGE_DIR)/kernel/kernel.inc

kernel: generic-kernel
kernel-clean: generic-kernel-clean
kernel-distclean: generic-kernel-distclean
