BASE_DIR=$(shell pwd)

SCRIPT_DIR=$(BASE_DIR)/scripts
KCONFIG_DIR=$(SCRIPT_DIR)/kconfig
CONFIG_DIR=$(BASE_DIR)/config

SOURCE_DIR=$(BASE_DIR)/sources
BUILD_DIR=$(BASE_DIR)/work
INITRD_DIR=$(BASE_DIR)/initrd-rootfs
STAGING_DIR=$(BASE_DIR)/staging
SKELETON_DIR=$(BASE_DIR)/skeleton
OUTPUT_DIR=$(BASE_DIR)/deploy
PACKAGE_DIR=$(BASE_DIR)/packages
BIN_DIR=$(BASE_DIR)/bin
ROM_DIR=$(OUTPUT_DIR)/roms

ifeq (.config, $(wildcard .config))
dot-config := 1
else
dot-config := 0
config-targets := 1
endif

ifneq ($(filter textconfig oldconfig defconfig menuconfig,$(MAKECMDGOALS)),)
config-targets := 1
dot-config := 0
endif

ifeq ($(dot-config),0)
all: .config

.config: oldconfig
	@echo "Configuration completed - type make to build your ROM"
else
-include .config

include $(CONFIG_DIR)/platforms/platforms.conf
include $(CONFIG_DIR)/payloads/payloads.conf

# Include the global settings and other checks
include $(SCRIPT_DIR)/Build.settings

# TARGET_ROM is what we are ultimately building - this should be
# specified by the platform files

TARGET_ROM ?= coreboot.rom
TARGET_ROM_FILE=$(OUTPUT_DIR)/$(TARGET_ROM)

# Choose the version of coreboot to build - this might be better
# elsewhere, but what the heck - its easy.

COREBOOT-$(CONFIG_COREBOOT_V2) = coreboot
COREBOOT-$(CONFIG_COREBOOT_V3) = coreboot-v3 roms

# Construct the list of packages we will be building

PKGLIST = $(COREBOOT-y) $(DEPENDS-y) $(PAYLOAD-y) $(HOSTTOOLS-y)

# Construct the various targets

PKG_clean=$(patsubst %, %-clean, $(PKGLIST))
PKG_distclean=$(patsubst %, %-distclean, $(PKGLIST))
PKG_extract=$(patsubst %, %-extract, $(PKGLIST))

# This is the top level target - for v2, the final deliverable is built
# by coreboot, for v3 it is built by us, so we have ifdef magic here

ifeq ($(CONFIG_COREBOOT_V2),y)
rom: $(HOSTTOOLS-y) payload $(COREBOOT-y)
else

# If compressing the payload in v3, parse the elf and tell lar to compress it.
# Parsing the elf without compression bloats the ROM with bss zeroes.
ifeq ($(CONFIG_USE_LZMA),y)
LAR_PAYLOAD_FLAGS=-a -e -C lzma
else
LAR_PAYLOAD_FLAGS=-a
endif
	
ifeq ($(or $(CONFIG_VSA_LEGACY), $(CONFIG_VSA_OPENVSA)),)
else
OPTIONROM_TARGETS+=geodevsa
endif

rom: $(HOSTTOOLS-y) payload $(COREBOOT-y)
	@ cp $(CBV3_OUTPUT) $(TARGET_ROM_FILE)
ifeq ($(CONFIG_VSA_LEGACY),y)
	@ $(STAGING_DIR)/bin/lar $(LAR_PAYLOAD_FLAGS) $(TARGET_ROM_FILE) $(SOURCE_DIR)/amd_vsa_lx_1.01.bin:blob/vsa
endif
ifeq ($(CONFIG_VSA_OPENVSA),y)
	@ echo "Adding OpenVSA: TODO FIXME - let's actually implement this?"
endif
	@ for file in `ls $(ROM_DIR)`; do \
		$(STAGING_DIR)/bin/lar $(LAR_PAYLOAD_FLAGS) $(TARGET_ROM_FILE) $(ROM_DIR)/$$file:$$file; \
	done
	@ $(STAGING_DIR)/bin/lar -z $(TARGET_ROM_FILE)
endif

payload: $(DEPENDS-y) $(PAYLOAD_TARGET)

extract: $(PKG_extract)

clean: $(PKG_clean)
	@ rm -rf $(INITRD_DIR) $(OUTPUT_DIR)

distclean:  $(PKG_distclean)
	@ rm -rf $(OUTPUT_DIR) $(STAGING_DIR) $(INITRD_DIR)	
	@ rm -f $(BASE_DIR).config

# Include the payload builder

ifneq ($(PAYLOAD_BUILD),)
include $(PAYLOAD_BUILD)
endif

# The following code gets all the make targets, but filters out the kernel
# targets which are implicitly set by the platform configuration

MKTARGETS:= $(shell ls $(PACKAGE_DIR)/*/*.mk)

include $(filter-out $(PACKAGE_DIR)/kernel/% $(PACKAGE_DIR)/coreboot-v2/% $(PACKAGE_DIR)/coreboot-v3/%,$(MKTARGETS))

include $(KERNEL_MK)

ifeq ($(CONFIG_COREBOOT_V2),y)
include $(CBV2_MK)
else
include $(PACKAGE_DIR)/coreboot-v3/coreboot-v3.mk
endif

endif

super-distclean: 
	@ make -C $(KCONFIG_DIR) clean
	@ rm -rf $(BUILD_DIR)
	@ rm -f .config tmpconfig.h .kconfig.d .config.old

ifeq ($(config-targets),1)

$(KCONFIG_DIR)/conf:
	make -C $(KCONFIG_DIR) conf

$(KCONFIG_DIR)/mconf:
	make -C $(KCONFIG_DIR) mconf

$(KCONFIG_DIR)/lxdialog/lxdialog:
	make -C $(KCONFIG_DIR)/lxdialog lxdialog


textconfig: $(KCONFIG_DIR)/conf
	@$(KCONFIG_DIR)/conf $(BASE_DIR)/Config.in

oldconfig: $(KCONFIG_DIR)/conf
	@$(KCONFIG_DIR)/conf -o $(BASE_DIR)/Config.in

defconfig: $(KCONFIG_DIR)/conf
	@$(KCONFIG_DIR)/conf -d $(BASE_DIR)/Config.in

menuconfig: $(KCONFIG_DIR)/lxdialog/lxdialog $(KCONFIG_DIR)/mconf
	@$(KCONFIG_DIR)/mconf $(BASE_DIR)/Config.in

endif
