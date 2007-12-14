QEMU_URL=http://fabrice.bellard.free.fr/qemu/
QEMU_SOURCE=qemu-0.9.0.tar.gz
QEMU_DIR=$(BUILD_DIR)/qemu
QEMU_SRC_DIR=$(QEMU_DIR)/qemu-0.9.0
QEMU_STAMP_DIR=$(QEMU_DIR)/stamps
QEMU_LOG_DIR=$(QEMU_DIR)/logs

QEMU_PATCHES=$(PACKAGE_DIR)/qemu/patches/qemu-bios-size.patch
QEMU_PATCHES+=$(PACKAGE_DIR)/qemu/patches/qemu-isa-bios-ram.patch
QEMU_PATCHES+=$(PACKAGE_DIR)/qemu/patches/qemu-piix-ram-size.patch

ifeq ($(CONFIG_VERBOSE),y)
QEMU_BUILD_LOG=/dev/stdout
QEMU_CONFIG_LOG=/dev/stdout
else
QEMU_BUILD_LOG=$(QEMU_LOG_DIR)/build.log
QEMU_CONFIG_LOG=$(QEMU_LOG_DIR)/config.log
endif

$(SOURCE_DIR)/$(QEMU_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(QEMU_URL)/$(QEMU_SOURCE)

$(QEMU_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(QEMU_SOURCE)
	@ echo "Unpacking qemu..."
	@ tar -C $(QEMU_DIR) -zxf $(SOURCE_DIR)/$(QEMU_SOURCE)
	@ touch $@

$(QEMU_STAMP_DIR)/.patched: $(QEMU_STAMP_DIR)/.unpacked
	@ echo "Patching qemu..."
	@ $(BIN_DIR)/doquilt.sh $(QEMU_SRC_DIR) $(QEMU_PATCHES)
	@ touch $@

$(QEMU_STAMP_DIR)/.configured: $(QEMU_STAMP_DIR)/.patched
	@ cd $(QEMU_SRC_DIR); ./configure --cc=$(CONFIG_QEMU_CC) --target-list=i386-softmmu > $(QEMU_CONFIG_LOG) 2>&1
	@ touch $@

$(QEMU_SRC_DIR)/i386-softmmu/qemu: $(QEMU_STAMP_DIR)/.configured
	@ make -C $(QEMU_SRC_DIR) CC=$(CONFIG_QEMU_CC) CCFLAGS="" CFLAGS="" LDFLAGS="" > $(QEMU_BUILD_LOG) 2>&1
	@ echo "the qemu executable is in $(QEMU_SRC_DIR)/i386-softmmu/"

$(QEMU_STAMP_DIR) $(QEMU_LOG_DIR):
	@ mkdir -p $@

qemu: $(QEMU_STAMP_DIR) $(QEMU_LOG_DIR) $(QEMU_SRC_DIR)/i386-softmmu/qemu

qemu-clean:
	$(MAKE) -C $(QEMU_SRC_DIR) clean 

qemu-distclean:
	@ rm -rf $(QEMU_DIR)/*

qemu-bom:
	echo "Package: qemu"
	echo "Source: $(QEMU_URL)/$(QEMU_SOURCE)"
	echo ""
