GRUB2_REVISION=7e743dc7b9262c132488d7bb601ea48e4f730c60
GRUB2_URL=http://coreboot.org/viewmtn/revision/tar/$(GRUB2_REVISION)
GRUB2_TAR=grub2-$(GRUB2_REVISION).tar

GRUB2_DIR=$(BUILD_DIR)/grub2
GRUB2_SRC_DIR=$(GRUB2_DIR)/$(GRUB2_REVISION)
GRUB2_STAMP_DIR=$(GRUB2_DIR)/stamps
GRUB2_LOG_DIR=$(GRUB2_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
GRUB2_CONFIG_LOG=/dev/stdout
GRUB2_BUILD_LOG=/dev/stdout
GRUB2_INSTALL_LOG=/dev/stdout
else
GRUB2_BUILD_LOG=$(GRUB2_LOG_DIR)/build.log
GRUB2_INSTALL_LOG=$(GRUB2_LOG_DIR)/install.log
GRUB2_CONFIG_LOG=$(GRUB2_LOG_DIR)/config.log
endif

GRUB2_CFG=$(PACKAGE_DIR)/grub2/conf/grub.cfg
GRUB2_MODULES=coreboot cat cmp iso9660 help lspci \
	      serial terminal lar terminfo memdisk ata ls \
              configfile boot hexdump linux multiboot ext2

HAVE_RUBY:=$(call find-tool,ruby)

ifeq ($(HAVE_RUBY),n)
$(error To build GRUB2, you need to install 'ruby')
endif

$(SOURCE_DIR)/$(GRUB2_TAR):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -O $@ $(GRUB2_URL)

$(GRUB2_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(GRUB2_TAR) | $(GRUB2_DIR) $(GRUB2_STAMP_DIR)
	@ tar -C $(GRUB2_DIR) -xf $(SOURCE_DIR)/$(GRUB2_TAR)
	@ touch $@

$(GRUB2_STAMP_DIR)/.configured: $(GRUB2_STAMP_DIR)/.unpacked | $(GRUB2_LOG_DIR)
	@ echo "Configuring GRUB2..."
	@ (cd $(GRUB2_SRC_DIR); sh ./autogen.sh > $(GRUB2_CONFIG_LOG) 2>&1)
	@ (cd $(GRUB2_SRC_DIR); export LIBS= CC= LDFLAGS= CFLAGS=; ./configure --with-platform=linuxbios --prefix=$(STAGING_DIR) >> $(GRUB2_CONFIG_LOG) 2>&1)
	@ touch $@

$(GRUB2_SRC_DIR)/grub-mkimage: $(GRUB2_STAMP_DIR)/.configured
	@ echo "Building GRUB2..."
	@ (cd $(GRUB2_SRC_DIR); make > $(GRUB2_CONFIG_LOG) 2>&1)

$(GRUB2_STAMP_DIR)/.installed: $(GRUB2_SRC_DIR)/grub-mkimage
	@ chmod uga+x $(GRUB2_SRC_DIR)/mkinstalldirs
	@ (cd $(GRUB2_SRC_DIR); make install > $(GRUB2_INSTALL_LOG) 2>&1)
	@ touch $@

$(GRUB2_DIR)/grub2.elf: $(GRUB2_STAMP_DIR)/.installed
	@ $(STAGING_DIR)/bin/grub-mkimage -o $@ $(GRUB2_MODULES)

$(GRUB2_STAMP_DIR)/.copied: $(GRUB2_DIR)/grub2.elf
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(GRUB2_DIR)/grub2.elf $(PAYLOAD_ELF)
	@ touch $@

$(GRUB2_DIR) $(GRUB2_LOG_DIR) $(GRUB2_STAMP_DIR):
	@ mkdir -p $@

grub2: $(GRUB2_STAMP_DIR)/.copied

grub2-clean:
	@ rm -f $(GRUB2_DIR)/grub2.lar
	@ rm -f $(GRUB2_DIR)/grub2.elf
	@ rm -f $(GRUB2_STAMP_DIR)/.copied
	@ rm -f $(GRUB2_STAMP_DIR)/.installed
ifneq ($(wildcard "$(GRUB_SRC_DIR)/Makefile"),)
	@ $(MAKE) -C $(GRUB2_SRC_DIR) clean > /dev/null 2>&1
endif

grub2-distclean:
	@ rm -rf $(GRUB2_DIR)/*
