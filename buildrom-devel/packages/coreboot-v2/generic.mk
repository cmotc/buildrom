# This is the Generic coreboot target

ifeq ($(CONFIG_PAYLOAD_OFW),y)
	CBV2_CONFIG=Config-lab.lb
	CBV2_PAYLOAD_FILE_EXT=elf.lzma
endif

ifeq ($(CONFIG_PAYLOAD_KERNEL),y)
	CBV2_CONFIG=Config-lab.lb
	CBV2_PAYLOAD_FILE_EXT=elf.lzma
endif

ifeq ($(CONFIG_PAYLOAD_LAB),y)
	CBV2_CONFIG=Config-lab.lb
	CBV2_PAYLOAD_FILE_EXT=elf.lzma
endif

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

coreboot: generic-coreboot
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
