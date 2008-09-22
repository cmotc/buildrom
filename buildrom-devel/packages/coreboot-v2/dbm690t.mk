# This is the AMD DBM690T coreboot target

CBV2_PATCHES=

# Make sure we have the tools we need to accomplish this
HAVE_IASL:=$(call find-tool,iasl)

ifeq ($(HAVE_IASL),n)
$(error To build coreboot, you need to install the 'iasl' tool)
endif

ifeq ($(CONFIG_PLATFORM_DBM690T),y)
ifeq ($(CONFIG_SIMNOW),y)
CBV2_PATCHES += $(PACKAGE_DIR)/coreboot-v2/patches/simnow.patch
endif
endif

include $(PACKAGE_DIR)/coreboot-v2/coreboot.inc

coreboot: generic-coreboot
coreboot-clean: generic-coreboot-clean
coreboot-distclean: generic-coreboot-distclean
