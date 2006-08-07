SOURCE_DIR=$(BASE_DIR)/sources
BUILD_DIR=$(BASE_DIR)/work
INITRD_DIR=$(BASE_DIR)/initrd-rootfs
STAGING_DIR=$(BASE_DIR)/staging
SKELETON_DIR=$(BASE_DIR)/skeleton
OUTPUT_DIR=$(BASE_DIR)/deploy
PACKAGE_DIR=$(BASE_DIR)/packages
BIN_DIR=$(BASE_DIR)/bin

CC=gcc
CFLAGS=-fpic -m32 -Os -march=i686 -I$(STAGING_DIR)/include
STRIP=strip

LIBGCC:=$(shell $(CC) $(LIBGCC_CFLAGS) -print-libgcc-file-name)

LDFLAGS=-nostdlib -L$(STAGING_DIR)/lib -Wl,-rpath-link,$(STAGING_DIR)/lib \
-Wl,--dynamic-linker,/lib/ld-uClibc.so.0
LIBS =  $(STAGING_DIR)/lib/crt1.o -lc $(LIBGCC)

HOST_CC=gcc
HOST_CFLAGS=
HOST_LDFLAGS=

export CC CFLAGS LDFLAGS LIBS
