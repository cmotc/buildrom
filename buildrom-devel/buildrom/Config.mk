# This is the configuration for the build system

# Uncomment this to see the output from the package builds
#VERBOSE=y

# Specify the commandline to use with mkelfimage
COMMAND_LINE=console=ttyS0,115200 video=gxfb:1024x768 mem=119m rdinit=/linuxrc

# Uncomment the packages you want from the following list
# Say 'y' here to build Marcelo's kexec-boot-loader
INITRD_KBL=y

# Say 'y' here to use it as a cheap substitute for kexec-tools
KBL_KEXEC_ONLY=y

# Say 'y' here to build busybox
INITRD_BUSYBOX=y

# Say 'y' here to build wireless tools
#INITRD_WIRELESS=n

# Say 'y' here to build the bootmenu
INITRD_BOOTMENU=y

# Say 'y' here to build uclibc as a shared library (probably a savings
# win if you selected more then one of the above)
UCLIBC_DYNAMIC=y

# say 'y' here to build a full rom image (minus the vsa)
LINUXBIOS_PACKAGE=y

#### Payload selection

# Uncomment this to select the old school elf target
PAYLOAD_TARGET=$(OUTPUT_DIR)/olpc-payload.elf

# Uncomment this to select the NRV2B compressed payload
# NOTE!  This doesn't work right now!
#PAYLOAD_TARGET=$(OUTPUT_DIR)/olpc-payload.elf.nrv2b

###########################################
# You shouldn't change anything under this point
###########################################

# Note:  An astute person would note that this is very inefficent - 
# we should use the INITRD_PACKAGES-$(INITRD_BUSYBOX) += busybox trick.

TARGETS=payload
INITRD_PACKAGES=

ifeq ($(INITRD_KBL), y)
INITRD_PACKAGES += kexec-boot-loader
endif

ifeq ($(INITRD_BUSYBOX),y)
INITRD_PACKAGES += busybox
endif

ifeq ($(INITRD_WIRELESS),y)
INITRD_PACKAGES += wireless-tools
endif

ifeq ($(INITRD_BOOTMENU),y)
INITRD_PACKAGES += bootmenu
endif

ifeq ($(INITRD_KEXEC_TOOLS),y)
INITRD_PACKAGES += kexec-tools
endif

ifeq ($(LINUXBIOS_PACKAGE), y)
TARGETS += linuxbios
endif
