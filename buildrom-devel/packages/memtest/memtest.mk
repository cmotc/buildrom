MEMTEST_URL=http://www.memtest86.com/
MEMTEST_SOURCE=memtest86-3.3.tar.gz
MEMTEST_DIR=$(BUILD_DIR)/memtest
MEMTEST_SRC_DIR=$(MEMTEST_DIR)/memtest86-3.3
MEMTEST_STAMP_DIR=$(MEMTEST_DIR)/stamps
MEMTEST_LOG_DIR=$(MEMTEST_DIR)/logs

ifeq ($(CONFIG_MEMTEST_SERIAL),y)
MEMTEST_CONFIG_TARGET=$(MEMTEST_STAMP_DIR)/.configured
MEMTEST_CONFIG=$(PACKAGE_DIR)/memtest/config.h.serial
else
MEMTEST_CONFIG_TARGET=$(MEMTEST_STAMP_DIR)/.unpacked
endif

ifeq ($(CONFIG_VERBOSE),y)
MEMTEST_BUILD_LOG=/dev/stdout
MEMTEST_INSTALL_LOG=/dev/stdout
else
MEMTEST_BUILD_LOG=$(MEMTEST_LOG_DIR)/build.log
MEMTEST_INSTALL_LOG=$(MEMTEST_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(MEMTEST_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(MEMTEST_URL)/$(MEMTEST_SOURCE)

$(MEMTEST_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(MEMTEST_SOURCE)
	@ echo "Unpacking memtest..."
	@ tar -C $(MEMTEST_DIR) -zxf $(SOURCE_DIR)/$(MEMTEST_SOURCE)
	@ touch $@	

$(MEMTEST_STAMP_DIR)/.configured: $(MEMTEST_STAMP_DIR)/.unpacked
	@ cp $(MEMTEST_SRC_DIR)/config.h $(MEMTEST_SRC_DIR)/config.h.bak
	@ cp $(MEMTEST_CONFIG) $(MEMTEST_SRC_DIR)/config.h
	@ touch $@
	
$(MEMTEST_SRC_DIR)/memtest: $(MEMTEST_CONFIG_TARGET)
	@ echo "Building memtest..."
	@ $(MAKE) -C $(MEMTEST_SRC_DIR) AS="$(AS) $(CROSS_ASFLAGS)" CC="$(CC) $(CROSS_CFLAGS) $(STACKPROTECT)" LD="$(LD) $(CROSS_LDFLAGS)" CFLAGS="$(CFLAGS)" memtest > $(MEMTEST_BUILD_LOG) 2>&1

$(MEMTEST_STAMP_DIR) $(MEMTEST_LOG_DIR):
	@ mkdir -p $@

memtest: $(MEMTEST_STAMP_DIR) $(MEMTEST_LOG_DIR) $(MEMTEST_SRC_DIR)/memtest
	@ install -d $(OUTPUT_DIR)
	@ install -m 0644 $(MEMTEST_SRC_DIR)/memtest $(PAYLOAD_ELF)

memtest-clean:
	@ echo "Cleaning memtest..."
	@ rm -f $(MEMTEST_STAMP_DIR)/.configured
ifneq ($(wildcard $(MEMTEST_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(MEMTEST_SRC_DIR) clean > /dev/null 2>&1
endif

memtest-distclean:
	@ rm -rf $(MEMTEST_DIR)/*
