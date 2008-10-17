.PHONY: openssl-extract openssl-patch openssl-config openssl-build \
	openssl openssl-install openssl-clean

SYSROOT_OPENSSL_SHARED = $(STAGING_DIR)/usr/lib/libcrypto.a
TARGET_OPENSSL_SHARED = $(TARGET_PATH)/usr/lib/libcrypto.so.0.9.7

openssl-extract: $(OPENSSL_PATH)/.extract-stamp

openssl-patch: $(OPENSSL_PATH)/.patch-stamp

openssl-config: $(OPENSSL_PATH)/.config-stamp

openssl-build: $(OPENSSL_PATH)/apps/openssl

openssl-install-sysroot: $(SYSROOT_OPENSSL_SHARED)
openssl-install-target: $(TARGET_OPENSSL_SHARED)

OPENSSL_CFLAGS		=	-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64

$(OPENSSL_PATH)/.extract-stamp:
	mkdir -p $(TARGET_BUILD_PATH)
	cd $(TARGET_BUILD_PATH); tar xzf $(SOURCE_PATH)/openssl/openssl-$(OPENSSL_VERSION).tar.gz
	touch $@

$(OPENSSL_PATH)/.patch-stamp: $(OPENSSL_PATH)/.extract-stamp
	$(SCRIPTS_PATH)/patch-kernel.sh $(OPENSSL_PATH) $(SOURCE_PATH)/openssl/ '*.patch'
	# sigh... we have to resort to this just to set a gcc flag.
	# grumble.. and of course make sure to escape any '/' in CFLAGS
	sed '/CFLAG=/s,/;, $(shell echo '$(TARGET_CFLAGS)' | sed -e 's/\//\\\\\//g')/;,' \
		$(OPENSSL_PATH)/Configure > $(OPENSSL_PATH)/Configure.mod
	mv -f $(OPENSSL_PATH)/Configure.mod $(OPENSSL_PATH)/Configure
	chmod a+x $(OPENSSL_PATH)/Configure
	touch $@

$(OPENSSL_PATH)/.config-stamp: $(OPENSSL_PATH)/.patch-stamp
	(cd $(OPENSSL_PATH); \
		CFLAGS="-DOPENSSL_NO_KRB5 -DOPENSSL_NO_IDEA -DOPENSSL_NO_MDC2 -DOPENSSL_NO_RC5 $(TARGET_CFLAGS)" \
		PATH=$(STAGING_DIR)/usr/bin:$(PATH) \
		./Configure linux-i386 --prefix=/ \
			--openssldir=/lib/ssl -L$(STAGING_DIR)/lib -ldl \
			-I$(STAGING_DIR)/usr/include $(OPENSSL_OPTS) threads \
			shared no-idea no-mdc2 no-rc5)
	touch $@

$(OPENSSL_PATH)/apps/openssl: $(OPENSSL_PATH)/.config-stamp
	PATH=$(STAGING_DIR)/usr/bin:$(PATH) $(MAKE) CC=i386-linux-uclibc-gcc -C $(OPENSSL_PATH) all build-shared
	# Work around openssl build bug to link libssl.so with libcrypto.so.
	-rm $(OPENSSL_PATH)/libssl.so.*.*.*
	$(MAKE) PATH=$(PATH):$(STAGING_DIR)/usr/bin \
		CC=i386-linux-uclibc-gcc -C $(OPENSSL_PATH) do_linux-shared
	touch $@

$(STAGING_DIR)/usr/lib/libcrypto.a: $(OPENSSL_PATH)/apps/openssl
	PATH=$(STAGING_DIR)/usr/bin:$(PATH) $(MAKE) \
		CC=$(TARGET_CC) INSTALL_PREFIX=$(STAGING_DIR)/usr \
		-C $(OPENSSL_PATH) install
	cp -fa $(OPENSSL_PATH)/libcrypto.so* $(STAGING_DIR)/usr/lib/
	chmod a-x $(STAGING_DIR)/usr/lib/libcrypto.so.0.9.7
	(cd $(STAGING_DIR)/usr/lib; \
	 ln -fs libcrypto.so.0.9.7 libcrypto.so; \
	 ln -fs libcrypto.so.0.9.7 libcrypto.so.0; \
	)
	cp -fa $(OPENSSL_PATH)/libssl.so* $(STAGING_DIR)/usr/lib/
	chmod a-x $(STAGING_DIR)/usr/lib/libssl.so.0.9.7
	(cd $(STAGING_DIR)/usr/lib; \
	 ln -fs libssl.so.0.9.7 libssl.so; \
	 ln -fs libssl.so.0.9.7 libssl.so.0; \
	)
	touch -c $@

$(TARGET_PATH)/usr/lib/libcrypto.so.0.9.7: $(STAGING_DIR)/usr/lib/libcrypto.a
	mkdir -p $(TARGET_PATH)/usr/lib
	cp -fa $(STAGING_DIR)/usr/lib/libcrypto.so* $(TARGET_PATH)/usr/lib/
	cp -fa $(STAGING_DIR)/usr/lib/libssl.so* $(TARGET_PATH)/usr/lib/
	#cp -fa $(STAGING_DIR)/bin/openssl $(TARGET_PATH)/bin/
	$(STRIPCMD) $(TARGET_PATH)/usr/lib/libssl.so.0.9.7
	$(STRIPCMD) $(TARGET_PATH)/usr/lib/libcrypto.so.0.9.7

$(TARGET_DIR)/usr/lib/libssl.a: $(STAGING_DIR)/usr/lib/libcrypto.a
	mkdir -p $(TARGET_DIR)/usr/include
	cp -a $(STAGING_DIR)/usr/include/openssl $(TARGET_DIR)/usr/include/
	cp -dpf $(STAGING_DIR)/usr/lib/libssl.a $(TARGET_DIR)/usr/lib/
	cp -dpf $(STAGING_DIR)/usr/lib/libcrypto.a $(TARGET_DIR)/usr/lib/
	touch -c $@

$(STAGING_DIR)/usr/lib/libz.so.$(OPENSSL_VERSION): $(OPENSSL_PATH)/libz.so.$(OPENSSL_VERSION)
	cp -dpf $(OPENSSL_PATH)/libz.a $(STAGING_DIR)/usr/lib/
	cp -dpf $(OPENSSL_PATH)/openssl.h $(STAGING_DIR)/usr/include/
	cp -dpf $(OPENSSL_PATH)/zconf.h $(STAGING_DIR)/usr/include/
	cp -dpf $(OPENSSL_PATH)/libz.so* $(STAGING_DIR)/usr/lib/
	ln -sf libz.so.$(OPENSSL_VERSION) $(STAGING_DIR)/usr/lib/libz.so.1
	chmod a-x $(STAGING_DIR)/usr/lib/libz.so.$(OPENSSL_VERSION)
	touch -c $@

$(TARGET_PATH)/usr/lib/libz.so.$(OPENSSL_VERSION): $(STAGING_DIR)/usr/lib/libz.so.$(OPENSSL_VERSION)
	mkdir -p $(TARGET_PATH)/usr/lib
	cp -dpf $(STAGING_DIR)/usr/lib/libz.so* $(TARGET_PATH)/usr/lib
	$(STRIPCMD) -s $(TARGET_PATH)/usr/lib/libz.so*
	touch -c $@

openssl-clean:
	PATH=$(STAGING_DIR)/usr/bin:$(PATH) $(MAKE) -C $(OPENSSL_PATH) clean
	rm -f $(OPENSSL_PATH)/.build-stamp $(OPENSSL_PATH)/.config-stamp

openssl: openssl-build
