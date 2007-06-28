CRC32SUM_URL=http://dev.laptop.org/~rsmith
CRC32SUM_SOURCE=crc32sum_0.1.0.tar.gz
CRC32SUM_DIR=$(BUILD_DIR)/crc32sum
CRC32SUM_SRC_DIR=$(CRC32SUM_DIR)/crc32sum_0.1.0
CRC32SUM_STAMP_DIR=$(CRC32SUM_DIR)/stamps
CRC32SUM_LOG_DIR=$(CRC32SUM_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
CRC32SUM_BUILD_LOG=/dev/stdout
CRC32SUM_CONFIG_LOG=/dev/stdout
else
CRC32SUM_BUILD_LOG=$(CRC32SUM_LOG_DIR)/build.log
CRC32SUM_CONFIG_LOG=$(CRC32SUM_LOG_DIR)/config.log
endif

$(SOURCE_DIR)/$(CRC32SUM_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(CRC32SUM_URL)/$(CRC32SUM_SOURCE)

$(CRC32SUM_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(CRC32SUM_SOURCE)
	@ echo "Unpacking crc32sum..."
	@ tar -C $(CRC32SUM_DIR) -zxf $(SOURCE_DIR)/$(CRC32SUM_SOURCE)
	@ touch $@	

$(CRC32SUM_SRC_DIR)/crc32sum: $(CRC32SUM_STAMP_DIR)/.unpacked
	@ echo "Building crc32sum..."
	@ ( export CC=$(HOST_CC); export CFLAGS=$(HOST_CFLAGS); \
	  export LDFLAGS=$(HOST_LDFLAGS); unset LIBS; \
	  $(MAKE) -C $(CRC32SUM_SRC_DIR) all > $(CRC32SUM_BUILD_LOG) 2>&1)

$(STAGING_DIR)/bin/crc32sum: $(CRC32SUM_SRC_DIR)/crc32sum
	@ install -d $(STAGING_DIR)/bin
	@ install -m 0755 $< $@

$(CRC32SUM_STAMP_DIR) $(CRC32SUM_LOG_DIR):
	@ mkdir -p $@

crc32sum: $(CRC32SUM_STAMP_DIR) $(CRC32SUM_LOG_DIR) $(STAGING_DIR)/bin/crc32sum

crc32sum-clean:
	@ $(MAKE) -C $(CRC32SUM_SRC_DIR) clean > /dev/null 2>&1

crc32sum-distclean:
	@ rm -rf $(CRC32SUM_DIR)/*

crc32sum-bom:
	echo "Package: crc32sum"
	echo "Source: $(CRC32SUM_URL)/$(CRC32SUM_SOURCE)"
	echo ""
