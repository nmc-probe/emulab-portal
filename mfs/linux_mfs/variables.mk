MFS_ARCH		=	i386
TOPDIR			=	$(PWD)
SOURCE_PATH		=	$(TOPDIR)/source
SCRIPTS_PATH		=	$(TOPDIR)/scripts
BUILDROOT_PATH		=	$(TOPDIR)/buildroot
TARBALL_PATH		=	$(TOPDIR)/tarballs

TARGET_BUILD_PATH	=	$(TOPDIR)/build
TARGET_PATH		=	$(TOPDIR)/target
TEMPLATE_PATH		=	$(TOPDIR)/target_template
TARGET_INITRAMFS	=	$(TOPDIR)/target.cpio.gz
FAKEROOT_ENVIRONMENT	=	$(TOPDIR)/$(BUILD)_fs_fakeroot.env

TARGET_CC		=	$(MFS_ARCH)-linux-uclibc-gcc
ifeq ($(MFS_ARCH),i386)
TARGET_CFLAGS		=	-Os -mtune=i386 -march=i386
else
TARGET_CFLAGS		=	-Os
endif
TARGET_MODULES		=	uclibc-install-target zlib-install-target busybox-install dropbear-install linux-modules-install openssl-install-target kexec-install tmcc-install imagezip-install frisbee-install e2fsprogs-install

BUILDROOT_PATH		=	$(TOPDIR)/buildroot
STAGING_DIR		=	$(BUILDROOT_PATH)/build_$(MFS_ARCH)/staging_dir/

#HOSTMAKE=make
#HOSTAR=ar
#HOSTAS=as
#HOSTCC=gcc
#HOSTCXX=g++
#HOSTLD=ld
#HOST_CFLAGS=-g -O2

#TOOLCHAIN_PATH="$(STAGING_DIR)/bin:$(STAGING_DIR)/usr/bin:$(PATH)"

CROSS_COMPILER_PREFIX=$(MFS_ARCH)-linux-uclibc-
STRIPCMD=$(STAGING_DIR)/usr/bin/$(CROSS_COMPILER_PREFIX)strip
#CC=$(STAGING_DIR)/usr/bin/$(MFS_ARCH)-linux-uclibc-gcc -Os  -I$(STAGING_DIR)/usr/include -I$(STAGING_DIR)/include --sysroot=$(STAGING_DIR)/ -isysroot $(STAGING_DIR) -mtune=$(MFS_ARCH) -march=$(MFS_ARCH)

# Hack for building uClibc -- it can't handle parallel make processes.
#MAKE1:=$(HOSTMAKE) MAKE="$(firstword $(HOSTMAKE)) -j1"

HOSTCC=gcc

HOST_CONFIGURE_OPTS=PATH=$(STAGING_DIR)/usr/bin:$(PATH) \
		AR_FOR_BUILD="$(HOSTAR)" \
		AS_FOR_BUILD="$(HOSTAS)" \
		CC_FOR_BUILD="$(HOSTCC)" \
		GCC_FOR_BUILD="$(HOSTCC)" \
		CXX_FOR_BUILD="$(HOSTCXX)" \
		LD_FOR_BUILD="$(HOSTLD)" \
		CFLAGS_FOR_BUILD="$(HOST_CFLAGS)" \
		CXXFLAGS_FOR_BUILD="$(HOST_CXXFLAGS)" \
		LDFLAGS_FOR_BUILD="$(HOST_LDFLAGS)" \
		AR_FOR_TARGET=$(CROSS_COMPILER_PREFIX)ar \
		AS_FOR_TARGET=$(CROSS_COMPILER_PREFIX)as \
		LD_FOR_TARGET=$(CROSS_COMPILER_PREFIX)ld \
		NM_FOR_TARGET=$(CROSS_COMPILER_PREFIX)nm \
		RANLIB_FOR_TARGET=$(CROSS_COMPILER_PREFIX)ranlib \
		STRIP_FOR_TARGET=$(CROSS_COMPILER_PREFIX)strip \
		OBJCOPY_FOR_TARGET=$(CROSS_COMPILER_PREFIX)objcopy

