# Common kernel file included by the targets

KERNEL_BASE_DIR ?= linux-$(KERNEL_VERSION)

KERNEL_DIR=$(BUILD_DIR)/kernel
KERNEL_SRC_DIR=$(KERNEL_DIR)/$(KERNEL_BASE_DIR)
KERNEL_STAMP_DIR=$(KERNEL_DIR)/stamps
KERNEL_LOG_DIR=$(KERNEL_DIR)/logs

ifeq ($(CONFIG_TARGET_64BIT),y)
KERNEL_BZIMAGE=$(KERNEL_SRC_DIR)/arch/x86_64/boot/bzImage
KERNEL_BUILD_ARCH=x86_64
else
KERNEL_BZIMAGE=$(KERNEL_SRC_DIR)/arch/i386/boot/bzImage
KERNEL_BUILD_ARCH=i386
endif

ifeq ($(CONFIG_VERBOSE),y)
KERNEL_FETCH_LOG=/dev/stdout
KERNEL_BUILD_LOG=/dev/stdout
KERNEL_INSTALL_LOG=/dev/stdout
else
KERNEL_FETCH_LOG=$(KERNEL_LOG_DIR)/fetch.log
KERNEL_BUILD_LOG=$(KERNEL_LOG_DIR)/build.log
KERNEL_INSTALL_LOG=$(KERNEL_LOG_DIR)/install.log
endif

$(KERNEL_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(KERNEL_SOURCE)
	@ mkdir -p $(KERNEL_DIR)
	@ echo "Unpacking kernel..."
	@ tar -C $(KERNEL_DIR) -jxf $(SOURCE_DIR)/$(KERNEL_SOURCE)
	@ touch $@

$(KERNEL_STAMP_DIR)/.unpacked-tiny: $(SOURCE_DIR)/$(TINY_SOURCE)	
	@ mkdir -p $(KERNEL_DIR)
	@ mkdir -p $(KERNEL_DIR)/tiny
	@ echo "Unpacking tiny patches..."
	@ tar -C $(KERNEL_DIR)/tiny -xzf $(SOURCE_DIR)/$(TINY_SOURCE)
	@ touch $@

ifneq ($(TINY_SOURCE),)
$(KERNEL_STAMP_DIR)/.patched: $(KERNEL_STAMP_DIR)/.unpacked $(KERNEL_STAMP_DIR)/.unpacked-tiny
else
$(KERNEL_STAMP_DIR)/.patched: $(KERNEL_STAMP_DIR)/.unpacked
endif
	@ echo "Patching kernel..."
	@ $(BIN_DIR)/doquilt.sh $(KERNEL_SRC_DIR) $(KERNEL_PATCHES)
	@ touch $@

$(KERNEL_SRC_DIR)/.config: $(KERNEL_STAMP_DIR)/.patched
	@ cat $(KERNEL_CONFIG) | sed -e s:^CONFIG_LOCALVERSION=.*:CONFIG_LOCALVERSION=\"$(ROM_VERSION)\": > $(KERNEL_SRC_DIR)/.config

$(KERNEL_BZIMAGE): $(KERNEL_SRC_DIR)/.config
	@ echo "Building kernel..."
	@ $(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(KERNEL_BUILD_ARCH) \
	KERNEL_CC="$(CC)" KERNEL_LD="$(LD)" > $(KERNEL_BUILD_LOG) 2>&1

$(OUTPUT_DIR)/bzImage: $(KERNEL_BZIMAGE)
	@ install -d $(OUTPUT_DIR)
	@ install -m 0644 $< $@ 

$(OUTPUT_DIR)/vmlinux: $(KERNEL_BZIMAGE)
	@ install -d $(OUTPUT_DIR)
	@ install -m 0644 $(KERNEL_SRC_DIR)/vmlinux $@
	
$(KERNEL_STAMP_DIR)/.headers: $(KERNEL_SRC_DIR)/.config $(STAGING_DIR)/host/bin/unifdef
	@ echo "Installing kernel headers..."
	@( export PATH=$(PATH):$(STAGING_DIR)/host/bin; \
	$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(KERNEL_BUILD_ARCH) \
	INSTALL_HDR_PATH=$(STAGING_DIR)/ headers_install > $(KERNEL_INSTALL_LOG) 2>&1)
	@ touch $@

$(KERNEL_STAMP_DIR) $(KERNEL_LOG_DIR):
	@ mkdir -p $@

generic-kernel: $(KERNEL_STAMP_DIR) $(KERNEL_LOG_DIR) $(OUTPUT_DIR)/bzImage $(OUTPUT_DIR)/vmlinux $(KERNEL_STAMP_DIR)/.headers

generic-kernel-clean:
	@ echo "Cleaning kernel..."
	@ if [ -d $(KERNEL_SRC_DIR) ]; then \
	$(MAKE) -C $(KERNEL_SRC_DIR) clean > /dev/null 2>&1; \
	fi

generic-kernel-distclean:
	@ rm -rf $(KERNEL_DIR)
