export src := $(shell pwd)
export srctree := $(src)
export srck := $(src)/scripts/kconfig
export obj := $(src)/build
export objk := $(src)/build/scripts/kconfig

export KERNELVERSION      := 0.1.0
export KCONFIG_AUTOHEADER := $(obj)/config.h
export KCONFIG_AUTOCONFIG := $(obj)/auto.conf

CONFIG_SHELL := sh
KBUILD_DEFCONFIG := scripts/defconfig
UNAME_RELEASE := $(shell uname -r)
MAKEFLAGS += --no-print-directory

# Make is silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q := @
endif

HOSTCC = gcc
HOSTCXX = g++
HOSTCFLAGS := -I$(srck) -I$(objk)
HOSTCXXFLAGS := -I$(srck) -I$(objk)


BASE_DIR:=$(shell pwd)

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

ifneq ($(filter config oldconfig defconfig menuconfig xconfig gconfig allyesconfig allnoconfig allmodconfig randconfig,$(MAKECMDGOALS)),)
config-targets := 1
dot-config := 0
endif

ifeq ($(dot-config),0)
all: prepare .config

.config: oldconfig
	@echo "Configuration completed - type make to build your ROM"
else
-include .config

# Pass -q to wget if the user doesn't want to see a download progressbar.
ifeq ($(CONFIG_SHOW_DOWNLOAD_PROGRESSBAR),y)
WGET_Q=
else
WGET_Q=-q
endif

DEPENDS-y=
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
COREBOOT-$(CONFIG_COREBOOT_V3) = coreboot-v3

# Add openvsa as a dependency if it is configured to be used; this makes sure
# that make distclean will clear out work/openvsa (see below)
ifeq ($(CONFIG_VSA_OPENVSA),y)
	DEPENDS-y+=openvsa
endif

# Construct the list of packages we will be building

PKGLIST = $(COREBOOT-y) $(DEPENDS-y) $(PAYLOAD-y) $(HOSTTOOLS-y)

# Construct the various targets

PKG_clean=$(patsubst %, %-clean, $(PKGLIST))
PKG_distclean=$(patsubst %, %-distclean, $(PKGLIST))
PKG_extract=$(patsubst %, %-extract, $(PKGLIST))

# This is the top level target - for v2, the final deliverable is built
# by coreboot, for v3 it is built by us, so we have ifdef magic here

ifeq ($(CONFIG_COREBOOT_V2),y)
rom: payload $(COREBOOT-y)
endif

ifeq ($(CONFIG_PAYLOAD_ONLY),y)
rom: payload
	@ echo ""
	@ echo "CONFIG_PAYLOAD_ONLY was set"
	@ echo ""
	@ echo "1. cp deploy/your_payload.elf coreboot/svn/payload.elf"
	@ echo "2. configure the payload to be payload.elf and build it."
	@ echo ""
endif

ifeq ($(CONFIG_COREBOOT_V3),y)

# If compressing the payload in v3, parse the elf and tell lar to compress it.
# Parsing the elf without compression bloats the ROM with bss zeroes.

LAR_PAYLOAD_FLAGS-y=-a -e
LAR_PAYLOAD_FLAGS-$(CONFIG_USE_LZMA) += -C lzma

rom: payload $(COREBOOT-y)
	@ mkdir -p $(shell dirname $(TARGET_ROM_FILE))
	@ cp $(CBV3_OUTPUT) $(TARGET_ROM_FILE)
	@ $(STAGING_DIR)/bin/lar $(LAR_PAYLOAD_FLAGS-y) $(TARGET_ROM_FILE) $(PAYLOAD_TARGET):normal/payload
	@ if [ -d $(ROM_DIR) ]; then \
		for file in `find $(ROM_DIR) -type f`; do \
		b=`echo $$file | sed -e s:^$(ROM_DIR)\/*::`; \
	        $(STAGING_DIR)/bin/lar $(LAR_PAYLOAD_FLAGS-y) \
		$(TARGET_ROM_FILE) $$file:$$b; \
		done; \
	fi
	@ $(STAGING_DIR)/bin/lar -z $(TARGET_ROM_FILE)
endif

# These empty dependencies are for the custom payload.
custom:
custom-clean:

payload: $(HOSTTOOLS-y) $(DEPENDS-y) $(PAYLOAD_TARGET)

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

INCMK=$(foreach mk,$(DEPENDS-y) $(PAYLOAD-y) $(HOSTTOOLS-y),$(PACKAGE_DIR)/$(mk)/$(mk).mk)

ifeq ($(CONFIG_COREBOOT_V2),y)
INCMK += $(PACKAGE_DIR)/coreboot-v2/coreboot-v2.mk
endif

ifeq ($(CONFIG_COREBOOT_V3),y)
INCMK += $(PACKAGE_DIR)/coreboot-v3/coreboot-v3.mk
endif

ifneq ($(INCMK),)
include $(INCMK)
endif

endif

super-distclean: 
	@ rm -rf build
	@ rm -rf $(BUILD_DIR)
	@ rm -f .config tmpconfig.h .kconfig.d .config.old .tmpconfig* ..config.tmp

prepare:
	$(Q)mkdir -p $(obj)/scripts/kconfig/lxdialog

include scripts/kconfig/Makefile

.PHONY: $(PHONY) prepare clean distclean

