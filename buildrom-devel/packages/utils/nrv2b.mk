NRV2B_URL=svn://coreboot.org/repos/trunk/coreboot-v2/util/nrv2b
NRV2B_TAG=3086

NRV2B_DIR=$(BUILD_DIR)/nrv2b
NRV2B_SRC_DIR=$(NRV2B_DIR)/svn
NRV2B_STAMP_DIR=$(NRV2B_DIR)/stamps
NRV2B_LOG_DIR=$(NRV2B_DIR)/logs
NRV2B_TARBALL=nrv2b-svn-$(NRV2B_TAG).tar.gz

ifeq ($(CONFIG_VERBOSE),y)
NRV2B_BUILD_LOG=/dev/stdout
NRV2B_FETCH_LOG=/dev/stdout
else
NRV2B_BUILD_LOG=$(NRV2B_LOG_DIR)/build.log
NRV2B_FETCH_LOG=$(NRV2B_LOG_DIR)/fetch.log
endif

$(SOURCE_DIR)/$(NRV2B_TARBALL):
	mkdir -p $(SOURCE_DIR)/nrv2b
	@ $(BIN_DIR)/fetchsvn.sh $(NRV2B_URL) $(SOURCE_DIR)/nrv2b \
	$(NRV2B_TAG) $@ > $(NRV2B_FETCH_LOG) 2>&1

$(NRV2B_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(NRV2B_TARBALL)
	@ tar -C $(NRV2B_DIR) -zxf $(SOURCE_DIR)/$(NRV2B_TARBALL)
	@ touch $@

$(NRV2B_SRC_DIR)/nrv2b: $(NRV2B_STAMP_DIR)/.unpacked
	@ (unset CFLAGS; unset LDFLAGS; \
	$(MAKE) -C $(NRV2B_SRC_DIR) \
        > $(NRV2B_BUILD_LOG) 2>&1)

$(STAGING_DIR)/bin/nrv2b: $(NRV2B_SRC_DIR)/nrv2b
	mkdir -p $(STAGING_DIR)/bin
	cp $< $@

$(NRV2B_STAMP_DIR) $(NRV2B_LOG_DIR):
	@ mkdir -p $@

nrv2b: $(NRV2B_STAMP_DIR) $(NRV2B_LOG_DIR) $(STAGING_DIR)/bin/nrv2b

nrv2b-clean:
	@ echo "Cleaning nrv2b..."
	@ $(MAKE) -C $(NRV2B_SRC_DIR) clean > /dev/null 2>&1

nrv2b-distclean:
	@ rm -r $(NRV2B_DIR)

