MKELFIMAGE_DIR=$(BUILD_DIR)/mkelfimage
MKELFIMAGE_SRC_DIR=$(MKELFIMAGE_DIR)/svn
MKELFIMAGE_STAMP_DIR=$(MKELFIMAGE_DIR)/stamps
MKELFIMAGE_LOG_DIR=$(MKELFIMAGE_DIR)/logs
MKELFIMAGE_PATCHES=

MKELFIMAGE_TAG=4645
MKELFIMAGE_TARBALL=mkelfimage-svn-$(MKELFIMAGE_TAG).tar.gz
MKELFIMAGE_URL=svn://coreboot.org/repos/trunk/util/mkelfImage

ifeq ($(CONFIG_VERBOSE),y)
MKELFIMAGE_FETCH_LOG=/dev/stdout
MKELFIMAGE_BUILD_LOG=/dev/stdout
MKELFIMAGE_CONFIG_LOG=/dev/stdout
else
MKELFIMAGE_FETCH_LOG=$(MKELFIMAGE_LOG_DIR)/fetch.log
MKELFIMAGE_BUILD_LOG=$(MKELFIMAGE_LOG_DIR)/build.log
MKELFIMAGE_CONFIG_LOG=$(MKELFIMAGE_LOG_DIR)/config.log
endif

$(MKELFIMAGE_STAMP_DIR) $(MKELFIMAGE_LOG_DIR):
	@ mkdir -p $@

$(SOURCE_DIR)/$(MKELFIMAGE_TARBALL): | $(MKELFIMAGE_LOG_DIR)
	@ echo "Fetching the mkelfimage rev $(MKELFIMAGE_TAG) code..."
	@ mkdir -p $(SOURCE_DIR)
	@ $(BIN_DIR)/fetchsvn.sh $(MKELFIMAGE_URL) $(SOURCE_DIR)/mkelfimage \
	$(MKELFIMAGE_TAG) $@ > $(MKELFIMAGE_FETCH_LOG) 2>&1

$(MKELFIMAGE_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(MKELFIMAGE_TARBALL) | $(MKELFIMAGE_STAMP_DIR) $(MKELFIMAGE_LOG_DIR) 
	@ echo "Unpacking mkelfimage..."
	@ tar -C $(MKELFIMAGE_DIR) -zxf $(SOURCE_DIR)/$(MKELFIMAGE_TARBALL)
	@ touch $@	

$(MKELFIMAGE_STAMP_DIR)/.patched: $(MKELFIMAGE_STAMP_DIR)/.unpacked
	@ echo "Patching mkelfimage..."
	@ $(BIN_DIR)/doquilt.sh $(MKELFIMAGE_SRC_DIR) $(MKELFIMAGE_PATCHES)
	@ touch $@

$(MKELFIMAGE_STAMP_DIR)/.configured: $(MKELFIMAGE_STAMP_DIR)/.patched
	@ ( export CC=$(HOST_CC); export HOST_CFLAGS="$(HOST_CFLAGS)"; \
	    export I386_CFLAGS="$(HOST_CFLAGS)"; \
	  export LDFLAGS=$(HOST_LDFLAGS); unset LIBS; \
	cd $(MKELFIMAGE_SRC_DIR); ./configure \
	  --with-i386 --without-ia64 > $(MKELFIMAGE_CONFIG_LOG) 2>&1 )
	@ touch $@

$(MKELFIMAGE_SRC_DIR)/objdir/sbin/mkelfImage: $(MKELFIMAGE_STAMP_DIR)/.configured
	@ echo "Building mkelfImage..."
	@ $(MAKE) -C $(MKELFIMAGE_SRC_DIR) all > $(MKELFIMAGE_BUILD_LOG) 2>&1

$(STAGING_DIR)/sbin/mkelfImage: $(MKELFIMAGE_SRC_DIR)/objdir/sbin/mkelfImage
	@ install -d $(STAGING_DIR)/sbin
	@ install -m 0755 $< $@

mkelfimage: $(STAGING_DIR)/sbin/mkelfImage

mkelfimage-clean:
	@ rm -f $(MKELFIMAGE_STAMP_DIR)/.configured
	@ rm -f $(STAGING_DIR)/sbin/mkelfImage
ifneq ($(wildcard $(MKELFIMAGE_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(MKELFIMAGE_SRC_DIR) clean 
endif

mkelfimage-distclean:
	@ rm -rf $(MKELFIMAGE_DIR)/*

mkelfimage-bom:
	echo "Package: mkelfimage"
	echo "Source: $(MKELFIMAGE_URL) rev $(MKELFIMAGE_TAG)"
	echo ""

mkelfimage-extract: $(MKELFIMAGE_STAMP_DIR)/.patched

