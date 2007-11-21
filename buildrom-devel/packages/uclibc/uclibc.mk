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
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(UCLIBC_URL)/$(UCLIBC_SOURCE)

$(UCLIBC_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(UCLIBC_SOURCE)
	@ echo "Unpacking uclibc..." 
	@ tar -C $(UCLIBC_DIR) -jxf $(SOURCE_DIR)/$(UCLIBC_SOURCE)
	@ touch $@	

$(UCLIBC_SRC_DIR)/.config: $(UCLIBC_STAMP_DIR)/.unpacked
	@ cat $(PACKAGE_DIR)/uclibc/conf/$(UCLIBC_CONFIG) | sed -e s:^KERNEL_HEADERS=.*:KERNEL_HEADERS=\"$(KERNEL_SRC_DIR)/include\": > $(UCLIBC_SRC_DIR)/.config

$(UCLIBC_SRC_DIR)/lib/libc.a: $(UCLIBC_SRC_DIR)/.config
	@ echo "Building uclibc..." 
	@ ( unset CFLAGS; unset LDFLAGS; \
	$(MAKE) -C $(UCLIBC_SRC_DIR) TARGET_ARCH="$(UCLIBC_ARCH)" \
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

$(UCLIBC_STAMP_DIR) $(UCLIBC_LOG_DIR):
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
