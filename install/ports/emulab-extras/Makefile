# ports collection makefile for: emulab-extras

PORTNAME=	emulab-extras
PORTVERSION=	1.0
CATEGORIES=	misc
MASTER_SITES=	#none
DISTFILES=      #none
EXTRACT_ONLY=	#none
COMMENT=	"Extra convenience packages for Emulab"

MAINTAINER=	testbed-ops@flux.utah.edu

NO_BUILD=	yes

#
# This prevents any ports from trying to run interactively - some, like the
# net-snmp port, ask silly questions without this option.
#
.MAKEFLAGS+=	-DBATCH

RUN_DEPENDS+=	\
        ${LOCALBASE}/bin/jove:${PORTSDIR}/editors/jove \
        ${LOCALBASE}/bin/emacs:${PORTSDIR}/editors/emacs \
        ${LOCALBASE}/bin/vim:${PORTSDIR}/editors/vim \
        ${LOCALBASE}/sbin/lsof:${PORTSDIR}/sysutils/lsof \
        ${LOCALBASE}/bin/ttcp:${PORTSDIR}/benchmarks/ttcp

do-install:	# empty

.include <bsd.port.mk>
