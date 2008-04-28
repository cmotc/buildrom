KEXEC_URL=http://www.xmission.com/~ebiederm/files/kexec/
KEXEC_SOURCE=kexec-tools-1.101.tar.gz
KEXEC_DIR=$(BUILD_DIR)/kexec-tools
KEXEC_SRC_DIR=$(KEXEC_DIR)/kexec-tools-1.101
KEXEC_STAMP_DIR=$(KEXEC_DIR)/stamps

$(KEXEC_SOURCE):
	mkdir -p $(SOURCE_DIR)
	@ wget $(WGET_Q) -P $(SOURCE_DIR) $(KEXEC_URL)/$(KEXEC_SOURCE)

$(KEXEC_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(KEXEC_SOURCE)
	tar -C $(KEXEC_DIR) -zxf $(SOURCE_DIR)/$(KEXEC_SOURCE)
	touch $@	

$(KEXEC_STAMP_DIR)/.configured: $(KEXEC_STAMP_DIR)/.unpacked
	(cd $(KEXEC_SRC_DIR); ./configure \
	--prefix=$(STAGING_DIR)\
	--with-zlib=$(STAGING_DIR))

$(KEXEC_SRC_DIR)/kexec-tools: $(KEXEC_STAMP_DIR)/.configured
	$(MAKE) -C $(KEXEC_SRC_DIR) \
	CFLAGS=$(CFLAGS) \
	LDFLAGS="$(LDFLAGS) -L$(STAGING_DIR)/lib --rpath-link,$(STAGING_DIR)/lib "

$(INITRD_DIR)/sbin/kexec-tools: $(KEXEC_SRC_DIR)/kexec-tools
	install -d $(INITRD)/sbin
	install -m 0744 $(KEXEC_SRC_DIR)/kexec-tools $(INITRD)/sbin

$(KEXEC_STAMP_DIR):
	mkdir -p $@

kexec-tools: $(KEXEC_STAMP_DIR) $(INITRD_DIR)/sbin/kexec-tools

kexec-tools-clean:
	@ rm -f $(KEXEC_STAMP_DIR)/.configured 
ifneq ($(wildcard $(KEXEC_SRC_DIR)/Makefile),)
	$(MAKE) -C $(KEXEC_SRC_DIR) clean
endif

kexec-tools-distclean:
	rm -rf $(KEXEC_DIR)/*

