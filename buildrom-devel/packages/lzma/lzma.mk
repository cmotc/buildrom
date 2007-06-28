LZMA_URL=http://switch.dl.sourceforge.net/sourceforge/sevenzip
LZMA_SOURCE=lzma443.tar.bz2
LZMA_DIR=$(BUILD_DIR)/lzma
LZMA_SRC_DIR=$(LZMA_DIR)/lzma-443
LZMA_STAMP_DIR=$(LZMA_DIR)/stamps
LZMA_LOG_DIR=$(LZMA_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
LZMA_BUILD_LOG=/dev/stdout
LZMA_CONFIG_LOG=/dev/stdout
else
LZMA_BUILD_LOG=$(LZMA_LOG_DIR)/build.log
LZMA_CONFIG_LOG=$(LZMA_LOG_DIR)/config.log
endif

$(SOURCE_DIR)/$(LZMA_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(LZMA_URL)/$(LZMA_SOURCE)

$(LZMA_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(LZMA_SOURCE)
	@ mkdir -p $(LZMA_SRC_DIR)
	@ tar -C $(LZMA_SRC_DIR) -jxf $(SOURCE_DIR)/$(LZMA_SOURCE)
	@ touch $@

$(LZMA_SRC_DIR)/C/7zip/Compress/LZMA_Alone/lzma: $(LZMA_STAMP_DIR)/.unpacked
	@ echo "Building lzma..."
	@ ( export CC=$(HOST_CC); export CFLAGS=$(HOST_CFLAGS); \
	export LDFLAGS=$(HOST_LDFLAGS); unset LIBS; \
	cd $(LZMA_SRC_DIR)/C/7zip/Compress/LZMA_Alone; \
	$(MAKE) -C $(LZMA_SRC_DIR)/C/7zip/Compress/LZMA_Alone -f makefile.gcc > $(LZMA_BUILD_LOG) 2>&1 )

$(STAGING_DIR)/bin/lzma: $(LZMA_SRC_DIR)/C/7zip/Compress/LZMA_Alone/lzma
	@ install -d $(STAGING_DIR)/bin
	@ install -m 0755 $< $@

$(LZMA_STAMP_DIR) $(LZMA_LOG_DIR):
	@ mkdir -p $@

lzma: $(LZMA_STAMP_DIR) $(LZMA_LOG_DIR) $(STAGING_DIR)/bin/lzma

lzma-clean:
	@ echo "Cleaning lzma..."
	@ $(MAKE) -C $(LZMA_SRC_DIR)/C/7zip/Compress/LZMA_Alone -f makefile.gcc clean > /dev/null 2>&1

lzma-distclean:
	@ rm -rf $(LZMA_DIR)/*
