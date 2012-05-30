# ports collection makefile for: emulab-pubsub

PORTNAME=	emulab-extras
PORTVERSION=	1.0
CATEGORIES=	misc
MASTER_SITES=	http://www.emulab.net/distributions/
DISTFILES=      ${PORTNAME}-${PORTVERSION}.tar.gz
WRKSRC=         ${WRKDIR}/${PORTNAME}-${PORTVERSION}

MAINTAINER=	testbed-ops@flux.utah.edu
COMMENT=	"Extra convenience packages for Emulab"

USE_GMAKE=	yes
INSTALLS_SHLIB=	yes

#
# This prevents any ports from trying to run interactively - some, like the
# net-snmp port, ask silly questions without this option.
#
.MAKEFLAGS+=	-DBATCH

RUN_DEPENDS+=	\
        ${LOCALBASE}/bin/jove:${PORTSDIR}/editors/jove \
        ${LOCALBASE}/sbin/lsof:${PORTSDIR}/sysutils/lsof \
        ${LOCALBASE}/bin/ttcp:${PORTSDIR}/benchmarks/ttcp

.include <bsd.port.mk>
