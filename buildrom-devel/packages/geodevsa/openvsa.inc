# Build target for openVSA - included from geodevsa.mk

OPENVSA_URL=svn://openbios.org/openvsa/trunk/openvsa
OPENVSA_TAG=6

OPENVSA_DIR=$(BUILD_DIR)/openvsa
OPENVSA_SRC_DIR=$(OPENVSA_DIR)/svn
OPENVSA_STAMP_DIR=$(OPENVSA_DIR)/stamps
OPENVSA_LOG_DIR=$(OPENVSA_DIR)/logs
OPENVSA_TARBALL=openvsa-svn-$(OPENVSA_TAG).tar.gz

ifeq ($(CONFIG_VERBOSE),y)
OPENVSA_BUILD_LOG=/dev/stdout
OPENVSA_FETCH_LOG=/dev/stdout
else
OPENVSA_BUILD_LOG=$(OPENVSA_LOG_DIR)/build.log
OPENVSA_FETCH_LOG=$(OPENVSA_LOG_DIR)/fetch.log
endif

$(SOURCE_DIR)/$(OPENVSA_TARBALL): | $(OPENVSA_LOG_DIR)
	@ mkdir -p $(SOURCE_DIR)/openvsa
	@ mkdir -p $(OPENVSA_LOG_DIR)
	@ echo "Fetching openvsa..."
	@ $(BIN_DIR)/fetchsvn.sh $(OPENVSA_URL) $(SOURCE_DIR)/openvsa \
	$(OPENVSA_TAG) $@ > $(OPENVSA_FETCH_LOG) 2>&1

$(OPENVSA_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(OPENVSA_TARBALL)
	@ mkdir -p $(OPENVSA_DIR)
	@ tar -C $(OPENVSA_DIR) -zxf $(SOURCE_DIR)/$(OPENVSA_TARBALL)
	@ mkdir -p $(OPENVSA_STAMP_DIR)
	@ touch $@

$(OPENVSA_SRC_DIR)/vsa_lx.bin: $(OPENVSA_STAMP_DIR)/.unpacked
	@ mkdir -p $(OPENVSA_LOG_DIR)
	@ echo "Building openvsa..."
	@(unset LDFLAGS; $(MAKE) -C $(OPENVSA_SRC_DIR) \
	> $(OPENVSA_BUILD_LOG) 2>&1)

$(GEODE_UNCOMPRESSED_VSA): $(OPENVSA_SRC_DIR)/vsa_lx.bin
	@ mkdir -p $(shell dirname $(GEODE_UNCOMPRESSED_VSA))
	@ cp $< $@

openvsa: $(OPENVSA_SRC_DIR)/vsa_lx.bin

openvsa-clean:
	@ if [ -d $(OPENVSA_SRC_DIR) ]; then \
	echo "Cleaning openvsa..."; \
	$(MAKE) -C $(OPENVSA_SRC_DIR) clean > /dev/null 2>&1; \
	fi

openvsa-distclean:
	@ rm -rf $(OPENVSA_DIR)

