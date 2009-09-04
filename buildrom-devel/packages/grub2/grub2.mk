GRUB2_URL=svn://svn.savannah.gnu.org/grub/trunk/grub2
GRUB2_TAG=1946

GRUB2_DIR=$(BUILD_DIR)/grub2
GRUB2_SRC_DIR=$(GRUB2_DIR)/svn
GRUB2_STAMP_DIR=$(GRUB2_DIR)/stamps
GRUB2_LOG_DIR=$(GRUB2_DIR)/logs

ifeq ($(CONFIG_VERBOSE),y)
GRUB2_FETCH_LOG=/dev/stdout
GRUB2_BUILD_LOG=/dev/stdout
GRUB2_INSTALL_LOG=/dev/stdout
else
GRUB2_BUILD_LOG=$(GRUB2_LOG_DIR)/build.log
GRUB2_INSTALL_LOG=$(GRUB2_LOG_DIR)/install.log
GRUB2_FETCH_LOG=$(GRUB2_LOG_DIR)/fetch.log
endif

GRUB2_MODULES=normal ls cat help ext2 iso9660 reiserfs xfs fat pc gpt ata serial memdisk multiboot linux boot cpio configfile search terminal

GRUB2_TARBALL=grub2-svn-$(GRUB2_TAG).tar.gz

GRUB2_MEMDISK_DIR=$(STAGING_DIR)/grub2_memdisk
GRUB2_MEMDISK_TARBALL=$(GRUB2_MEMDISK_DIR)/memdisk.tar

ifeq ($(shell if [ -f $(PACKAGE_DIR)/grub2/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD) ]; then echo 1; fi),1)
	GRUB2_CONFIG = $(PACKAGE_DIR)/grub2/conf/customconfig--$(PAYLOAD)--$(COREBOOT_VENDOR)-$(COREBOOT_BOARD)
else
	GRUB2_CONFIG = $(GRUB2_SRC_DIR)/configs/defconfig
endif

$(SOURCE_DIR)/$(GRUB2_TARBALL): | $(GRUB2_LOG_DIR)
	@ mkdir -p $(SOURCE_DIR)/grub2
	@ $(BIN_DIR)/fetchsvn.sh $(GRUB2_URL) $(SOURCE_DIR)/grub2 \
	$(GRUB2_TAG) $(SOURCE_DIR)/$(GRUB2_TARBALL) \
	> $(GRUB2_FETCH_LOG) 2>&1

$(GRUB2_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(GRUB2_TARBALL) | $(GRUB2_STAMP_DIR) $(GRUB2_DIR)
	@ echo "Unpacking grub2..."
	@ tar -C $(GRUB2_DIR) -zxf $(SOURCE_DIR)/$(GRUB2_TARBALL)
	@ touch $@      

$(GRUB2_STAMP_DIR)/.configured: $(GRUB2_STAMP_DIR)/.unpacked
	@ touch $@

$(GRUB2_SRC_DIR)/grub-mkelfimage: $(GRUB2_STAMP_DIR)/.configured
ifeq ($(findstring customconfig,$(GRUB2_CONFIG)),customconfig)
	@ echo "Using custom config $(GRUB2_CONFIG)"
endif
	@ echo "Building grub2..."
	@ ln -sf $(GRUB2_SRC_DIR)/config.log $(GRUB2_LOG_DIR)
	@ (cd $(GRUB2_SRC_DIR) ; sh ./autogen.sh >> $(GRUB2_BUILD_LOG) 2>&1)
	@ (cd $(GRUB2_SRC_DIR) ; export LIBS= CC= LDFLAGS= CFLAGS=; ./configure --with-platform=coreboot --prefix=$(STAGING_DIR) >> $(GRUB2_BUILD_LOG) 2>&1)
	@ make -C $(GRUB2_SRC_DIR) >> $(GRUB2_BUILD_LOG) 2>&1

$(GRUB2_STAMP_DIR)/.installed: $(GRUB2_SRC_DIR)/grub-mkelfimage
	@ chmod uga+x $(GRUB2_SRC_DIR)/mkinstalldirs
	@ (cd $(GRUB2_SRC_DIR); make install > $(GRUB2_INSTALL_LOG) 2>&1)
	@ touch $@

$(GRUB2_MEMDISK_TARBALL): $(GRUB2_STAMP_DIR)/.configured $(GRUB2_MEMDISK_DIR)
	@ (cd $(GRUB2_MEMDISK_DIR); mkdir -p boot/grub)
	@ cp $(PACKAGE_DIR)/grub2/boot/grub/grub.cfg $(GRUB2_MEMDISK_DIR)/boot/grub/
	@ (cd $(GRUB2_MEMDISK_DIR); tar -cf $@ boot)


$(GRUB2_DIR)/grub2.elf: $(GRUB2_STAMP_DIR)/.installed $(GRUB2_MEMDISK_TARBALL)
	@ (cd $(GRUB2_SRC_DIR) ; $(STAGING_DIR)/bin/grub-mkelfimage -d . -o $@ $(GRUB2_MODULES) -m $(GRUB2_MEMDISK_TARBALL) --prefix='(memdisk)/boot/grub')

$(GRUB2_STAMP_DIR)/.copied: $(GRUB2_DIR)/grub2.elf
	@ mkdir -p $(shell dirname $(PAYLOAD_ELF))
	@ cp $(GRUB2_DIR)/grub2.elf $(PAYLOAD_ELF)
	@ touch $@

$(GRUB2_STAMP_DIR) $(GRUB2_LOG_DIR) $(GRUB2_MEMDISK_DIR):
	@ mkdir -p $@

grub2: $(GRUB2_STAMP_DIR) $(GRUB2_LOG_DIR) $(GRUB2_STAMP_DIR)/.copied

grub2-clean:
	@ echo "Cleaning grub2..."
	@ rm -f $(GRUB2_DIR)/grub2.elf
	@ rm -f $(GRUB2_STAMP_DIR)/.configured
	@ rm -f $(GRUB2_STAMP_DIR)/.copied
ifneq ($(wildcard $(GRUB2_SRC_DIR)/Makefile),)
	@ $(MAKE) -C $(GRUB2_SRC_DIR) clean > /dev/null 2>&1
endif

grub2-distclean:
	@ rm -rf $(GRUB2_DIR)/*

grub2-extract: $(GRUB2_STAMP_DIR)/.patched

