# "toplevel" kernel.mk - this is where we decide
# which of the platform specific files to actually
# include

KERNELMK-y=
KERNELMK-$(CONFIG_PLATFORM_NORWICH) = $(PACKAGE_DIR)/kernel/norwich.mk
KERNELMK-$(CONFIG_PLATFORM_MSM800SEV) = $(PACKAGE_DIR)/kernel/msm800sev.mk
KERNELMK-$(CONFIG_PLATFORM_ALIX1C) = $(PACKAGE_DIR)/kernel/alix1c.mk
KERNELMK-$(CONFIG_PLATFORM_ALIX2C3) = $(PACKAGE_DIR)/kernel/alix2c3.mk
KERNELMK-$(CONFIG_PLATFORM_DB800) = $(PACKAGE_DIR)/kernel/norwich.mk
KERNELMK-$(CONFIG_PLATFORM_DBE61) = $(PACKAGE_DIR)/kernel/norwich.mk
KERNELMK-$(CONFIG_PLATFORM_GA_M57SLI_S4) = $(PACKAGE_DIR)/kernel/m57sli.mk
KERNELMK-$(CONFIG_PLATFORM_TYAN_S2881) = $(PACKAGE_DIR)/kernel/tyan-s2881.mk
KERNELMK-$(CONFIG_PLATFORM_TYAN_S2882) = $(PACKAGE_DIR)/kernel/tyan-s2882.mk
KERNELMK-$(CONFIG_PLATFORM_TYAN_S2891) = $(PACKAGE_DIR)/kernel/tyan-s2891.mk
KERNELMK-$(CONFIG_PLATFORM_TYAN_S2892) = $(PACKAGE_DIR)/kernel/tiny-2.6.22.mk
KERNELMK-$(CONFIG_PLATFORM_TYAN_S2895) = $(PACKAGE_DIR)/kernel/tiny-2.6.22.mk
KERNELMK-$(CONFIG_PLATFORM_SUPERMICRO_H8DMR) = $(PACKAGE_DIR)/kernel/supermicro-h8dmr.mk
KERNELMK-$(CONFIG_PLATFORM_SUPERMICRO_H8DME) = $(PACKAGE_DIR)/kernel/supermicro-h8dme.mk
KERNELMK-$(CONFIG_PLATFORM_SERENGETI_CHEETAH) = $(PACKAGE_DIR)/kernel/serengeti_cheetah.mk
KERNELMK-$(CONFIG_PLATFORM_QEMU-X86) = $(PACKAGE_DIR)/kernel/qemu.mk

# buildrom platforms that don't have a kernel .mk
#KERNELMK-$(CONFIG_PLATFORM_ASUS_A8V_E_SE) =
#KERNELMK-$(CONFIG_PLATFORM_CHEETAH_FAM10) =
#KERNELMK-$(CONFIG_PLATFORM_GA_2761GXDK) =

ifeq ($(KERNELMK-y),)
$(error "You do not have a kernel .mk file defined for this platform")
endif

include $(KERNELMK-y)
