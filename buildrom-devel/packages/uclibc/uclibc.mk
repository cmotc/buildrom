# Defaults, if not set in the platform config
ifeq ($(CONFIG_TARGET_64BIT),y)
UCLIBC_VER ?= 0.9.29
UCLIBC_ARCH ?= x86_64
UCLIBC_CONFIG ?= defconfig-x86_64
else
UCLIBC_VER ?= 0.9.28
UCLIBC_ARCH ?= i386
UCLIBC_CONFIG ?= defconfig
endif

ifeq ($(findstring defconfig,$(UCLIBC_CONFIG)),defconfig)
ifeq ($(shell if [ -f $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	UCLIBC_CONFIG = customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
endif
endif

UCLIBC_URL=http://www.uclibc.org/downloads
UCLIBC_SOURCE=uClibc-$(UCLIBC_VER).tar.bz2
UCLIBC_DIR=$(BUILD_DIR)/uclibc
UCLIBC_SRC_DIR=$(UCLIBC_DIR)/uClibc-$(UCLIBC_VER)
UCLIBC_STAMP_DIR=$(UCLIBC_DIR)/stamps
UCLIBC_LOG_DIR=$(UCLIBC_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
UCLIBC_BUILD_LOG=/dev/stdout
UCLIBC_INSTALL_LOG=/dev/stdout
else
UCLIBC_BUILD_LOG=$(UCLIBC_LOG_DIR)/build.log
UCLIBC_INSTALL_LOG=$(UCLIBC_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(UCLIBC_SOURCE):
	@ echo "Downloading uclibc..." 
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(UCLIBC_URL)/$(UCLIBC_SOURCE)

$(UCLIBC_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(UCLIBC_SOURCE) | $(UCLIBC_STAMP_DIR) $(UCLIBC_DIR)
	@ echo "Unpacking uclibc..." 
	@ tar -C $(UCLIBC_DIR) -jxf $(SOURCE_DIR)/$(UCLIBC_SOURCE)
	@ touch $@	

$(UCLIBC_SRC_DIR)/.config: $(UCLIBC_STAMP_DIR)/.unpacked
	@ cat $(PACKAGE_DIR)/uclibc/conf/$(UCLIBC_CONFIG) | sed -e s:^KERNEL_HEADERS=.*:KERNEL_HEADERS=\"$(KERNEL_SRC_DIR)/include\": > $(UCLIBC_SRC_DIR)/.config

$(UCLIBC_SRC_DIR)/lib/libc.a: $(UCLIBC_SRC_DIR)/.config
	@ echo "Building uclibc..." 
ifneq ($(findstring defconfig,$(UCLIBC_CONFIG)),defconfig)
	@ echo "Using custom config $(PACKAGE_DIR)/uclibc/conf/$(UCLIBC_CONFIG)"
endif
	@ ( unset CFLAGS; unset LDFLAGS; \
	$(MAKE) $(PARALLEL_MAKE) -C $(UCLIBC_SRC_DIR) TARGET_ARCH="$(UCLIBC_ARCH)" \
	CC="$(CC) $(CROSS_CFLAGS)" LD="$(LD) $(CROSS_LDFLAGS)" \
	HOSTCC="$(HOST_CC)" KERNEL_SOURCE="$(KERNEL_SRC_DIR)" \
	RUNTIME_PREFIX="/" \
	SHARED_LIB_LOADER_PATH="/lib" \
	SHARED_LIB_LOADER_PREFIX="/lib" \
	all > $(UCLIBC_BUILD_LOG) 2>&1)

$(STAGING_DIR)/lib/libc.a: $(UCLIBC_SRC_DIR)/lib/libc.a
	@ $(MAKE) -C $(UCLIBC_SRC_DIR) \
	PREFIX= \
	DEVEL_PREFIX=$(STAGING_DIR)/ \
	RUNTIME_PREFIX=$(STAGING_DIR)/ \
	install_runtime install_dev > $(UCLIBC_INSTALL_LOG) 2>&1

$(UCLIBC_SRC_DIR)/utils/ldd: $(UCLIBC_SRC_DIR)/lib/libc.a
	@ $(MAKE) -C $(UCLIBC_SRC_DIR)/utils ldd

$(STAGING_DIR)/bin/ldd: $(UCLIBC_SRC_DIR)/utils/ldd
	@ install -m 755 -d $(STAGING_DIR)/bin
	@ install -m 755 $< $@

$(UCLIBC_STAMP_DIR) $(UCLIBC_LOG_DIR) $(UCLIBC_DIR):
	@ mkdir -p $@

uclibc: $(UCLIBC_STAMP_DIR) $(UCLIBC_LOG_DIR) $(STAGING_DIR)/lib/libc.a

uclibc-clean:
	@ echo "Cleaning uclibc..."
	@ $(MAKE) -C $(UCLIBC_SRC_DIR) clean > /dev/null 2>&1

uclibc-distclean:
	@ rm -rf $(UCLIBC_DIR)/*

uclibc-bom:
	@ echo "Package: uclibc"
	@ echo "Source: $(UCLIBC_URL)/$(UCLIBC_SOURCE)"
	@ echo ""

uclibc-extract: $(UCLIBC_STAMP_DIR)/.unpacked

uclibc-config: $(UCLIBC_STAMP_DIR)/.unpacked
ifeq ($(shell if [ -f $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ cp -f $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) $(UCLIBC_SRC_DIR)/.config
endif
ifeq (uclibc,$(filter uclibc,$(PAYLOAD-y)))
	@ echo "Configure uclibc..."
	@ $(MAKE) -C $(UCLIBC_SRC_DIR) TARGET_ARCH="$(UCLIBC_ARCH)" menuconfig
	@ echo
ifeq ($(shell if [ -f $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	@ echo "Found an existing custom configuration file:"
	@ echo "  $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)"
	@ echo "I've copied it back to the source directory for modification."
	@ echo "Remove the above file and re-run this command if you want to create a new custom configuration from scratch for this payload/board."
	@ echo
endif
	@ cp -f $(UCLIBC_SRC_DIR)/.config $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
	@ echo "Your custom uclibc config file has been saved as $(PACKAGE_DIR)/uclibc/conf/customconfig--$(PAYLOAD)--$(UCLIBC_ARCH)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)."
	@ echo
else
	@ echo "Your payload does not require uclibc."
endif
