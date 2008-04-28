UNIFDEF_URL=http://www.cs.cmu.edu/~ajw/public/dist/
UNIFDEF_SOURCE=unifdef-1.0.tar.gz
UNIFDEF_DIR=$(BUILD_DIR)/unifdef
UNIFDEF_SRC_DIR=$(UNIFDEF_DIR)/unifdef-1.0
UNIFDEF_STAMP_DIR=$(UNIFDEF_DIR)/stamps
UNIFDEF_LOG_DIR=$(UNIFDEF_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
UNIFDEF_BUILD_LOG=/dev/stdout
UNIFDEF_CONFIG_LOG=/dev/stdout
else
UNIFDEF_BUILD_LOG=$(UNIFDEF_LOG_DIR)/build.log
UNIFDEF_CONFIG_LOG=$(UNIFDEF_LOG_DIR)/config.log
endif

$(SOURCE_DIR)/$(UNIFDEF_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(UNIFDEF_URL)/$(UNIFDEF_SOURCE)

$(UNIFDEF_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(UNIFDEF_SOURCE) | $(UNIFDEF_STAMP_DIR)
	@ tar -C $(UNIFDEF_DIR) -zxf $(SOURCE_DIR)/$(UNIFDEF_SOURCE)
	@ rm -f $(UNIFDEF_SRC_DIR)/unifdef 
	@ rm -f $(UNIFDEF_SRC_DIR)/unifdef.o
	@ touch $@	

$(UNIFDEF_SRC_DIR)/unifdef: $(UNIFDEF_STAMP_DIR) $(UNIFDEF_LOG_DIR) $(UNIFDEF_STAMP_DIR)/.unpacked
	@ echo "Building unifdef (host)..."
	@ $(MAKE) -C $(UNIFDEF_SRC_DIR) CC=$(HOST_CC) > $(UNIFDEF_BUILD_LOG) 2>&1


$(STAGING_DIR)/host/bin/unifdef: $(UNIFDEF_SRC_DIR)/unifdef
	@ install -d $(STAGING_DIR)/host/bin
	@ install -m 0755 $< $@

$(UNIFDEF_STAMP_DIR) $(UNIFDEF_LOG_DIR):
	@ mkdir -p $@

unifdef: $(STAGING_DIR)/host/bin/unifdef

unifdef-clean:
ifneq ($(wildcard $(UNIFDEF_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(UNIFDEF_SRC_DIR) clean > /dev/null 2>&1
endif

unifdef-distclean:
	@ rm -rf $(UNIFDEF_DIR)/*

unifdef-bom:
	echo "Package: unifdef"
	echo "Source: $(UNIFDEF_URL)/$(UNIFDEF_SOURCE)"
	echo ""

.PHONY: unifdef

unifdef-extract: $(UNIFDEF_STAMP_DIR)/.unpacked
