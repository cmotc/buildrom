MKELFIMAGE_URL=http://www.infradead.org/~jcrouse
MKELFIMAGE_SOURCE=mkelfImage-2.5.tar.gz
MKELFIMAGE_DIR=$(BUILD_DIR)/mkelfimage
MKELFIMAGE_SRC_DIR=$(MKELFIMAGE_DIR)/mkelfImage-2.5
MKELFIMAGE_STAMP_DIR=$(MKELFIMAGE_DIR)/stamps
MKELFIMAGE_LOG_DIR=$(MKELFIMAGE_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
MKELFIMAGE_BUILD_LOG=/dev/stdout
MKELFIMAGE_CONFIG_LOG=/dev/stdout
else
MKELFIMAGE_BUILD_LOG=$(MKELFIMAGE_LOG_DIR)/build.log
MKELFIMAGE_CONFIG_LOG=$(MKELFIMAGE_LOG_DIR)/config.log
endif

$(SOURCE_DIR)/$(MKELFIMAGE_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(MKELFIMAGE_URL)/$(MKELFIMAGE_SOURCE)

$(MKELFIMAGE_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(MKELFIMAGE_SOURCE)
	@ echo "Unpacking mkelfimage..."
	@ tar -C $(MKELFIMAGE_DIR) -zxf $(SOURCE_DIR)/$(MKELFIMAGE_SOURCE)
	@ touch $@	

$(MKELFIMAGE_STAMP_DIR)/.configured: $(MKELFIMAGE_STAMP_DIR)/.unpacked
	@ ( export CC=$(HOST_CC); export CFLAGS=$(HOST_CFLAGS); \
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

$(MKELFIMAGE_STAMP_DIR) $(MKELFIMAGE_LOG_DIR):
	@ mkdir -p $@

mkelfimage: $(MKELFIMAGE_STAMP_DIR) $(MKELFIMAGE_LOG_DIR) $(STAGING_DIR)/sbin/mkelfImage

mkelfimage-clean:
	$(MAKE) -C $(MKELFIMAGE_SRC_DIR) clean 

mkelfimage-distclean:
	@ rm -rf $(MKELFIMAGE_DIR)/*

mkelfimage-bom:
	echo "Package: mkelfimage"
	echo "Source: $(MKELFIMAGE_URL)/$(MKELFIMAGE_SOURCE)"
	echo ""
