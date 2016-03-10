# ports collection makefile for: emulab-tipserv
# Date created:         15 June 2015
# Whom:                 testbed-ops@flux.utah.edu

.include "../emulab-boss/Makefile.emulab"

PORTNAME=	emulab-tipserv
PORTVERSION=	${EMULAB_PORTVERSION}
CATEGORIES=	misc
MASTER_SITES=	#none
DISTFILES=	#none
EXTRACT_ONLY=	#none

MAINTAINER=	testbed-ops@flux.utah.edu
COMMENT=	"Meta-port for an Emulab tipserv node"

NO_BUILD=	yes

#
# This prevents any ports from trying to configure interactively.
#
BATCH=		yes
.MAKEFLAGS+=	-DBATCH

LIB_DEPENDS=	\
	libtelnet.so:${PORTSDIR}/misc/libtelnet

##
## XXX this is a newer version of ipmitool than what the FreeBSD port
## currently uses.
##
#RUN_DEPENDS=	\
#	ipmitool:${PORTSDIR}/misc/ipmitool-devel

# Use the standard version as of 2016Q1 ports.
RUN_DEPENDS=	\
	ipmitool:${PORTSDIR}/sysutils/ipmitool

RUN_DEPENDS+=	\
	git:${PORTSDIR}/devel/git \
	gmake:${PORTSDIR}/devel/gmake \
        netcat:${PORTSDIR}/net/netcat \
	sudo:${PORTSDIR}/security/sudo

do-install:	# empty

.include <bsd.port.mk>
