#
# XXX hacked up Emulab version of isc-dhcp30-server/Makefile to be standalone
# for dhcp30-client. We have no local mods to this version of dhcp, we just
# need a dhclient program that works on multiple interfaces at once, hence we
# keep this version alive.
# From:
#
# ex:ts=8
# Ports collection makefile for:    dhcp
# Date created:         7 Mar 1996
# Whom:                 se
#
# $FreeBSD: ports/net/isc-dhcp30-server/Makefile,v 1.135 2009/07/22 00:11:47 jpaetzel Exp $
#

PORTNAME=	dhcp
PORTVERSION=	3.0.7
PORTREVISION=	${DHCP_PORTREVISION}
CATEGORIES=	misc net
MASTER_SITES=	${MASTER_SITE_ISC}
MASTER_SITE_SUBDIR=	dhcp dhcp/dhcp-3.0-history
PKGNAMEPREFIX=	isc-
PKGNAMESUFFIX=	30-client
DISTNAME=	${PORTNAME}-${RELEASE}${VERSION}${PATCHLEVEL}

MAINTAINER=	jpaetzel@FreeBSD.org
COMMENT?=	The ISC Dynamic Host Configuration Protocol server

PORTREVISION_SERVER=	5
PORTREVISION_CLIENT=	1
PORTREVISION_RELAY=	0
PORTREVISION_DEVEL=	0

UNIQUENAME=	${PKGNAMEPREFIX}${PORTNAME}${PKGNAMESUFFIX}

# PORTREVISION handling
DHCP_PORTREVISION=	${PORTREVISION_CLIENT}

.include <bsd.port.pre.mk>

# Global variables
#

HAS_CONFIGURE=	yes
CONFIGURE_ARGS=	--subsys client
ALL_TARGET=	all.client
INSTALL_TARGET=	install.client
SCRIPTS_ENV+=	PKG_PREFIX=${PREFIX}

MAN5=		dhclient.conf.5 dhclient.leases.5
MAN8=		dhclient.8 dhclient-script.8
MAN5+=		dhcp-eval.5 dhcp-options.5

MSG_FILE=	${.CURDIR}/pkg-message
DESCR=		${.CURDIR}/pkg-descr
PKGINSTALL=	${.CURDIR}/pkg-install
PKGDEINSTALL=	${PKGINSTALL}
PKGMESSAGE=	${WRKDIR}/pkg-message
PLIST=		${.CURDIR}/pkg-plist

# Local variables
#

# for instance, possible versions are:
#	1.2.r3.4 (or 1.2.b3.4), 1.2.r3 (or 1.2.b3), 1.2.3, 1.2
# which have to become:
#	1.2rc3pl4 (or 1.2beta3pl4), 1.2rc3 (or 1.2beta3), 1.2.3, 1.2
# so, the magic things are:
VERSION=
PATCHLEVEL=
.if ${PORTVERSION:R:E:M[br]*} != ""
RELEASE=	${PORTVERSION:R:R}
VERSION=	${PORTVERSION:R:E:S/b/beta/:S/r/rc/}
PATCHLEVEL=	pl${PORTVERSION:E}
.elif ${PORTVERSION:E:M[br]*} != ""
RELEASE=	${PORTVERSION:R}
VERSION=	${PORTVERSION:E:S/b/beta/:S/r/rc/}
#.elif ${PORTVERSION:R:E} != ""
#RELEASE=	${PORTVERSION:R}
#PATCHLEVEL=	pl${PORTVERSION:E}
.else
RELEASE=	${PORTVERSION}
.endif

PATCH_SUBDIRS=	common minires dst omapip
PATCH_SUBDIRS+=	client

.if !defined(NOPORTDOCS)
PORTDOCS=	LICENSE README RELNOTES
.endif
BIN_FILES=	dhclient
LOCAL_CONF_FILES=	dhclient.conf
SAMP_FILES=	client/dhclient.conf
DATA_FILES=	dhclient.leases

SAMP_SUFX=	.sample

CONF_DIR=	${PREFIX}/etc
SCHEMA_DIR=	${PREFIX}/share/${PKGBASE}
DOCSDIR=	${PREFIX}/share/doc/${PKGBASE}
DATADIR=	/var/db

PLIST_SUB+=	SCHEMA_DIR="${SCHEMA_DIR:S,^${PREFIX}/,,}"
.if defined(WITH_DHCP_LDAP)
PLIST_SUB+=	LDAP=""
.else
PLIST_SUB+=	LDAP="@comment "
.endif
REINPLACE_SUB=	PREFIX=${PREFIX}
.if !defined(WITHOUT_DHCP_PARANOIA)
SUB_LIST+=	PARANOIA=YES
.else
SUB_LIST+=	PARANOIA=NO
.endif
.if !defined(WITHOUT_DHCP_JAIL)
SUB_LIST+=	JAIL=YES
.else
SUB_LIST+=	JAIL=NO
.endif
PKGMESSAGE_SUB=	PREFIX="${PREFIX}" MAN1PREFIX="${MAN1PREFIX}" \
		DOCSDIR="${DOCSDIR}" SCHEMA_DIR="${SCHEMA_DIR}"

# Post-extract
#

post-extract: extract-omshell extract-script

extract-omshell:
	@${MKDIR} ${WRKSRC}/omshell
	@${MV} ${WRKSRC}/dhcpctl/omshell.? ${WRKSRC}/omshell
	@${CP} ${FILESDIR}/omshell::Makefile.dist \
		${WRKSRC}/omshell/Makefile.dist

extract-script:
	@${CP} ${FILESDIR}/client::scripts::freebsd ${WRKSRC}/client/scripts/freebsd

# Post-patch
#

post-patch: patch-scripts patch-makefile-conf \
	    patch-makefiles-dist patch-man-pages \
	    patch-pkgmessage patch-site-conf

patch-scripts:
	@${REINPLACE_CMD} ${REINPLACE_SUB:S/$/!g/:S/^/ -e s!%%/:S/=/%%!/} \
		${WRKSRC}/client/dhclient.conf \
		${WRKSRC}/client/scripts/freebsd

patch-site-conf:
	@${ECHO_CMD} CFLAGS += -DENABLE_POLLING_MODE >> ${WRKSRC}/site.conf

patch-makefile-conf:
	@${REINPLACE_CMD} -e 's|^DEBUG[ 	]*=|# DEBUG ?=|g' \
		${WRKSRC}/Makefile.conf

patch-makefiles-dist:
.for subdir in ${PATCH_SUBDIRS}
	@${REINPLACE_CMD} -e 's|^CFLAGS[ 	]*=|CFLAGS +=|g' \
		${WRKSRC}/${subdir}/Makefile.dist
.endfor

# temporary hack - no patch file needed for this typo.
patch-man-pages:
	@${REINPLACE_CMD} -e '/^\.Fd$$/d' ${WRKSRC}/dhcpctl/dhcpctl.3

patch-pkgmessage:
	@${SED} ${PKGMESSAGE_SUB:S/$/!g/:S/^/ -e s!%%/:S/=/%%!/} \
		${MSG_FILE} > ${PKGMESSAGE}
.if defined(WITH_DHCP_LDAP)
	@${REINPLACE_CMD} -e 's|^%%LDAP%%||g' ${PKGMESSAGE}
.else
	@${REINPLACE_CMD} -e '/^%%LDAP%%/d' ${PKGMESSAGE}
.endif


# Post-install
#

POST-INSTALL=	parallel-post-install install-rc-script configure-package \
		display-message
.ORDER: ${POST-INSTALL}
post-install: ${POST-INSTALL}

parallel-post-install: \
	strip-binary-files \
	install-doc-files install-sample-files \
	create-conf-files create-data-files

strip-binary-files:
.for f in ${BIN_FILES}
.if exists(${PREFIX}/bin/${f})
	@${STRIP_CMD} ${PREFIX}/bin/${f}
.endif
.if exists(${PREFIX}/sbin/${f})
	@${STRIP_CMD} ${PREFIX}/sbin/${f}
.endif
.endfor

install-doc-files:
.if !defined(NOPORTDOCS)
	@${MKDIR} ${DOCSDIR}
.for f in ${PORTDOCS}
	@${INSTALL_DATA} ${WRKSRC}/${f} ${DOCSDIR}
.endfor
.endif

install-sample-files:
.for f in ${SAMP_FILES}
	@${INSTALL_DATA} ${WRKSRC}/${f} ${CONF_DIR}/${f:T}${SAMP_SUFX}
.endfor

create-conf-files:
.for f in ${LOCAL_CONF_FILES}
.if !exists(${CONF_DIR}/${f})
	@${TOUCH} ${CONF_DIR}/${f}
.endif
.endfor

create-data-files:
.for f in ${DATA_FILES}
.if !exists(${DATADIR}/${f})
	@${TOUCH} ${DATADIR}/${f}
.endif
.endfor

configure-package:

display-message:
	@${ECHO_MSG}
	@${CAT} ${PKGMESSAGE}
	@${ECHO_MSG}

.include <bsd.port.post.mk>
