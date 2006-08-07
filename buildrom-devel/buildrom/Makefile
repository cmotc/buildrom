BASE_DIR=$(shell pwd)

include Config.mk
include Vars.mk

PKGLIST=uclibc kernel $(INITRD_PACKAGES)

ifeq ($(LINUXBIOS_PACKAGE),y)
PKGLIST += linuxbios
endif

PKG_clean=$(patsubst %, %-clean, $(PKGLIST))
PKG_distclean=$(patsubst %, %-distclean, $(PKGLIST))

# Payload target should be defined in Config.mk - but if it makes it here,
# then just select the default

PAYLOAD_TARGET ?= $(OUTPUT_DIR)/olpc-payload.elf

all: $(TARGETS)

payload: $(PAYLOAD_TARGET)

$(OUTPUT_DIR)/initrd.uncompressed: uclibc $(INITRD_PACKAGES)
	@ cp -af $(SKELETON_DIR)/* $(INITRD_DIR)
	@ chmod 0755 $(INITRD_DIR)/linuxrc

	@ echo "Cleaning unneeded libraries..."
	@ ( export LDD="$(STAGING_DIR)/bin/ldd"; \
	    for file in `$(BASE_DIR)/bin/checklibs.pl \
	    --verify --silent --script $(INITRD_DIR)`; \
	    do rm $(INITRD_DIR)/lib/$$file; done )

	@ echo "Building the initrd..."
	@ install -d $(OUTPUT_DIR)
	@ cd $(INITRD_DIR); find . | cpio -o -H newc 2> /dev/null > $@

$(OUTPUT_DIR)/initrd: $(OUTPUT_DIR)/initrd.uncompressed
	@  gzip -9 -c -n $< > $@

# Note that we refuse to continue if the ELF image is too big

$(OUTPUT_DIR)/olpc-payload-uncompressed.elf: kernel $(OUTPUT_DIR)/initrd.uncompressed mkelfimage
	@ echo "Building the uncompressed ELF payload..."
	@ rm -f $@
	@ $(STAGING_DIR)/sbin/mkelfImage --command-line="$(COMMAND_LINE)" \
	--ramdisk=$(OUTPUT_DIR)/initrd.uncompressed \
	$(OUTPUT_DIR)/vmlinux $@
	@ chmod 0644 $@

$(OUTPUT_DIR)/olpc-payload.elf: kernel $(OUTPUT_DIR)/initrd mkelfimage
	@ echo "Building the ELF payload..."
	@ rm -f $@
	@ $(STAGING_DIR)/sbin/mkelfImage --command-line="$(COMMAND_LINE)" \
	--ramdisk=$(OUTPUT_DIR)/initrd $(OUTPUT_DIR)/bzImage $@
	@ chmod 0644 $@
	@ $(BIN_DIR)/checkrom.sh $@

$(OUTPUT_DIR)/olpc-payload.elf.nrv2b: nrv2b $(OUTPUT_DIR)/olpc-payload-uncompressed.elf
	@ echo "Compressing the ELF payload with nrv2b..."
	@ $(STAGING_DIR)/bin/nrv2b e \
	$(OUTPUT_DIR)/olpc-payload-uncompressed.elf \
	2>/dev/null $@
	@ $(BIN_DIR)/checkrom.sh $@

clean: $(PKG_clean)
	@ rm -rf $(INITRD_DIR) $(OUTPUT_DIR)

distclean:  $(PKG_distclean)
	@ rm -rf $(OUTPUT_DIR) $(STAGING_DIR) $(INITRD_DIR)	

# Finally, include all of the package targets
include $(PACKAGE_DIR)/*/*.mk
