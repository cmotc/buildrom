KERNEL_VERSION=2.6.18-rc2-olpc1
KERNEL_URL=http://crank.laptop.org/~jcrouse/
KERNEL_SOURCE=linux-$(KERNEL_VERSION).tar.gz
KERNEL_DIR=$(BUILD_DIR)/kernel
KERNEL_SRC_DIR=$(KERNEL_DIR)/linux-$(KERNEL_VERSION)
KERNEL_STAMP_DIR=$(KERNEL_DIR)/stamps
KERNEL_LOG_DIR=$(KERNEL_DIR)/logs

ifeq ($(VERBOSE),y)
KERNEL_BUILD_LOG=/dev/stdout
else
KERNEL_BUILD_LOG=$(KERNEL_LOG_DIR)/build.log
endif

$(SOURCE_DIR)/$(KERNEL_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(KERNEL_URL)/$(KERNEL_SOURCE)

$(KERNEL_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(KERNEL_SOURCE)
	@ echo "Unpacking kernel..."
	@ tar -C $(KERNEL_DIR) -zxf $(SOURCE_DIR)/$(KERNEL_SOURCE)
	@ touch $@	

$(KERNEL_SRC_DIR)/.config: $(KERNEL_STAMP_DIR)/.unpacked
	@ cp $(PACKAGE_DIR)/kernel/conf/defconfig $(KERNEL_SRC_DIR)/.config

$(KERNEL_SRC_DIR)/arch/i386/boot/bzImage: $(KERNEL_SRC_DIR)/.config
	@ echo "Building kernel..."
	@ $(MAKE) -C $(KERNEL_SRC_DIR) ARCH=i386 \
	KERNEL_CC=$(CC) KERNEL_LD=$(LD) > $(KERNEL_BUILD_LOG) 2>&1

$(OUTPUT_DIR)/bzImage: $(KERNEL_SRC_DIR)/arch/i386/boot/bzImage
	@ install -d $(OUTPUT_DIR)
	@ install -m 0644 $< $@ 

$(OUTPUT_DIR)/vmlinux: $(KERNEL_SRC_DIR)/arch/i386/boot/bzImage
	@ install -d $(OUTPUT_DIR)
	@ install -m 0644 $(KERNEL_SRC_DIR)/vmlinux $@

$(KERNEL_STAMP_DIR) $(KERNEL_LOG_DIR):
	@ mkdir -p $@

kernel: $(KERNEL_STAMP_DIR) $(KERNEL_LOG_DIR) $(OUTPUT_DIR)/bzImage $(OUTPUT_DIR)/vmlinux

kernel-clean:
	@ echo "Cleaning kernel..."
	@ $(MAKE) -C $(KERNEL_SRC_DIR) clean > /dev/null 2>&1

kernel-distclean:
	@ rm -rf $(KERNEL_DIR)/*
