# "toplevel" coreboot-v2.mk - this is where we decide
# which of the platform specific files to actually
# include

# Most platforms use the generic target
CBV2MK-y=$(PACKAGE_DIR)/coreboot-v2/generic.mk

# All Geode LX targets use the same .mk file
CBV2MK-$(CONFIG_PLATFORM_GEODE) = $(PACKAGE_DIR)/coreboot-v2/geodelx.mk

CBV2MK-$(CONFIG_PLATFORM_GA_2761GXDK) = $(PACKAGE_DIR)/coreboot-v2/ga-2761gxdk.mk
CBV2MK-$(CONFIG_PLATFORM_SERENGETI_CHEETAH) = $(PACKAGE_DIR)/coreboot-v2/serengeti_cheetah.mk
CBV2MK-$(CONFIG_PLATFORM_CHEETAH_FAM10) = $(PACKAGE_DIR)/coreboot-v2/serengeti_cheetah.mk

include $(CBV2MK-y)
