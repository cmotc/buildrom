KBL_URL=http://hera.kernel.org/~marcelo/olpc
KBL_SOURCE=kexec-boot-loader.tar.gz
KBL_DIR=$(BUILD_DIR)/kexec-boot-loader
KBL_SRC_DIR=$(KBL_DIR)/kexec-boot-loader
KBL_STAMP_DIR=$(KBL_DIR)/stamps
KBL_LOG_DIR=$(KBL_DIR)/logs

ifeq ($(KBL_KEXEC_ONLY),y)
KBL_PATCHES += $(PACKAGE_DIR)/kexec-boot-loader/kexec-only.patch
KBL_LDFLAGS=
KBL_TARGET=$(INITRD_DIR)/sbin/kbl-kexec
else
KBL_PATCHES = $(PACKAGE_DIR)/kexec-boot-loader/makedevs.patch 
KBL_PATCHES += $(PACKAGE_DIR)/kexec-boot-loader/bl_autocreate_proc_dir.patch
KBL_LDFLAGS=-static
KBL_TARGET=$(INITRD_DIR)/kbl
endif

ifeq ($(VERBOSE),y)
KBL_BUILD_LOG=/dev/stdout
KBL_INSTALL_LOG=/dev/stdout
else
KBL_BUILD_LOG=$(KBL_LOG_DIR)/build.log
KBL_INSTALL_LOG=$(KBL_LOG_DIR)/install.log
endif

$(SOURCE_DIR)/$(KBL_SOURCE):
	@ mkdir -p $(SOURCE_DIR)
	@ wget -P $(SOURCE_DIR) $(KBL_URL)/$(KBL_SOURCE)

$(KBL_STAMP_DIR)/.unpacked: $(SOURCE_DIR)/$(KBL_SOURCE)
	@ echo "Unpacking kexec-boot-loader..."
	@ tar -C $(KBL_DIR) -zxf $(SOURCE_DIR)/$(KBL_SOURCE)
	@ touch $@	

$(KBL_STAMP_DIR)/.patched: $(KBL_STAMP_DIR)/.unpacked
	@ echo "Patching kexec-boot-loader..."
	@ mkdir -p $(KBL_SRC_DIR)/patches
	@ echo "# kexec-boot-loader series" > $(KBL_SRC_DIR)/patches/series
	@ for file in $(KBL_PATCHES); do \
		echo `basename $$file` >> $(KBL_SRC_DIR)/patches/series; \
		cp $$file $(KBL_SRC_DIR)/patches; \
	 done
	@ (cd $(KBL_SRC_DIR); quilt push -a)
	@ touch $@

$(KBL_SRC_DIR)/olpc-boot-loader: $(KBL_STAMP_DIR)/.patched
	@ echo "Building kexec-boot-loader..."
	@ $(MAKE) -C $(KBL_SRC_DIR) LDFLAGS="$(KBL_LDFLAGS) $(LDFLAGS) -gc-sections" UCLIBCLIBS="$(LIBS)" all > $(KBL_BUILD_LOG) 2>&1

$(KBL_TARGET): $(KBL_SRC_DIR)/olpc-boot-loader
	@ install -d $(INITRD_DIR)/sbin
	@ install -m 0755 $< $@
	@ $(STRIP) $@

$(KBL_STAMP_DIR) $(KBL_LOG_DIR):
	@ mkdir -p $@

kexec-boot-loader: $(KBL_STAMP_DIR) $(KBL_LOG_DIR) $(KBL_TARGET)

kexec-boot-loader-clean:
	@ echo "Cleaning kexec-boot-loader..."
	@ $(MAKE) -C $(KBL_SRC_DIR) clean > /dev/null 2>&1

kexec-boot-loader-distclean:
	@ rm -rf $(KBL_DIR)/*

.PHONY: kexec-boot-loader-message
