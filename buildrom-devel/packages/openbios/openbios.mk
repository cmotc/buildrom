# Build the OpenBIOS payload

OPENBIOS_SVN_URL=svn://openbios.org/openbios/openbios-devel
OPENBIOS_SVN_TAG=186

OPENBIOS_DIR=$(BUILD_DIR)/openbios
OPENBIOS_SRC_DIR=$(OPENBIOS_DIR)/svn
OPENBIOS_BUILD_DIR=$(OPENBIOS_DIR)/svn
OPENBIOS_STAMP_DIR=$(OPENBIOS_DIR)/stamps
OPENBIOS_LOG_DIR=$(OPENBIOS_DIR)/logs

OPENBIOS_OUTPUT=$(OPENBIOS_SRC_DIR)/obj-x86/openbios-builtin.elf

OPENBIOS_TARBALL=openbios-svn-$(OPENBIOS_SVN_TAG).tar.gz
OPENBIOS_PATCHES=

ifeq ($(CONFIG_VERBOSE),y)
OPENBIOS_FETCH_LOG=/dev/stdout
OPENBIOS_BUILD_LOG=/dev/stdout
OPENBIOS_CONFIG_LOG=/dev/stdout
else
OPENBIOS_FETCH_LOG=$(OPENBIOS_LOG_DIR)/fetch.log
OPENBIOS_BUILD_LOG=$(OPENBIOS_LOG_DIR)/build.log
OPENBIOS_CONFIG_LOG=$(OPENBIOS_LOG_DIR)/config.log
endif

# Check for fcode-utils.
HAVE_FCODE_UTILS:=$(call find-tool,detok)

ifeq ($(HAVE_FCODE_UTILS),n)
$(error To build OpenBIOS, you need to install 'fcode-utils')
endif

$(SOURCE_DIR)/$(OPENBIOS_TARBALL):
	@ echo "Fetching OpenBIOS..."
	@ echo "SVN Checkout rev $(OPENBIOS_SVN_TAG)"
	@ $(BIN_DIR)/fetchsvn.sh $(OPENBIOS_SVN_URL) $(SOURCE_DIR)/openbios \
	$(OPENBIOS_SVN_TAG) $@ > $(OPENBIOS_FETCH_LOG) 2>&1

$(OPENBIOS_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(OPENBIOS_TARBALL)
	@ echo "Unpacking OpenBIOS..."
	@ tar -C $(OPENBIOS_DIR) -xf $(SOURCE_DIR)/$(OPENBIOS_TARBALL)
	@ touch $@

$(OPENBIOS_STAMP_DIR)/.patched: $(OPENBIOS_STAMP_DIR)/.unpacked
	@ echo "Patching OpenBIOS..."
	@ $(BIN_DIR)/doquilt.sh $(OPENBIOS_SRC_DIR) $(OPENBIOS_PATCHES)
	@ touch $@

$(OPENBIOS_STAMP_DIR)/.configured: $(OPENBIOS_STAMP_DIR)/.patched
	@ echo "Configuring OpenBIOS..."
	@ (cd $(OPENBIOS_SRC_DIR); config/scripts/switch-arch x86 > $(OPENBIOS_CONFIG_LOG) 2>&1)
	@ touch $@

$(OPENBIOS_OUTPUT): $(OPENBIOS_STAMP_DIR)/.configured
	@ echo "Building OpenBIOS..."
	@ (cd $(OPENBIOS_BUILD_DIR); make > $(OPENBIOS_BUILD_LOG) 2>&1)

$(OPENBIOS_STAMP_DIR) $(OPENBIOS_LOG_DIR):
	@ mkdir -p $@

openbios: $(OPENBIOS_STAMP_DIR) $(OPENBIOS_LOG_DIR) $(OPENBIOS_OUTPUT)
	@ mkdir -p $(OUTPUT_DIR)
	@ install -m 0644 $(OPENBIOS_OUTPUT) $(OUTPUT_DIR)/openbios-payload.elf

openbios-clean:
	@ echo "Cleaning OpenBIOS..."
	@ rm -f $(OPENBIOS_STAMP_DIR)/.configured
ifneq ($(wildcard $(OPENBIOS_BUILD_DIR)/Makefile),)
	@ $(MAKE) -C $(OPENBIOS_BUILD_DIR) clean > /dev/null 2>&1
endif

openbios-distclean:
	@ rm -rf $(OPENBIOS_DIR)/*

