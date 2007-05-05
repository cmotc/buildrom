# Build file for the OLPC LAB kernel

KERNEL_URL=git://dev.laptop.org/olpc-2.6
KERNEL_SOURCE=linux-olpc-2.6-$(KERNEL_TAG).tar.gz
KERNEL_BASE_DIR=git
KERNEL_CONFIG=$(PACKAGE_DIR)/kernel/conf/defconfig-olpc

KERNEL_PATCHES += $(PACKAGE_DIR)/kernel/patches/ext3.patch
TINY_DIR=$(PACKAGE_DIR)/kernel/patches/tiny
KERNEL_PATCHES += $(shell ls $(TINY_DIR)/*.patch)

include $(PACKAGE_DIR)/kernel/kernel.inc

$(SOURCE_DIR)/$(KERNEL_SOURCE):
	@ echo "Fetching the kernel source..."
	@ mkdir -p $(SOURCE_DIR)/kernel
	@ $(BIN_DIR)/fetchgit.sh $(KERNEL_URL) $(SOURCE_DIR)/kernel \
	$(KERNEL_TAG) $(SOURCE_DIR)/$(KERNEL_SOURCE) \
	> $(KERNEL_FETCH_LOG) 2>&1

kernel: generic-kernel
kernel-clean: generic-kernel-clean
kernel-distclean: generic-kernel-distclean
