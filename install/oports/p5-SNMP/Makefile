#
# This port has been "expired" from the official FreeBSD ports tree.
#
# New ports collection makefile for:	p5-SNMP
# Date created:				May 5th 1997
# Whom:	      				James FitzGibbon <jfitz@FreeBSD.org>
#
# $FreeBSD: ports/net-mgmt/p5-SNMP/Makefile,v 1.27 2008/09/26 14:43:11 clsung Exp $
#

PORTNAME=	SNMP
PORTVERSION=	4.2.7.1
CATEGORIES=	misc net-mgmt perl5
MASTER_SITES=	SF
MASTER_SITE_SUBDIR=	net-snmp
PKGNAMEPREFIX=	p5-
DISTNAME=	ucd-snmp-${PORTVERSION}

MAINTAINER=	perl@FreeBSD.org
COMMENT=	A perl5 module for interfacing with the CMU SNMP library

LIB_DEPENDS=	snmp.4:${PORTSDIR}/misc/net-snmp4

WRKSRC=		${WRKDIR}/${DISTNAME}/perl/SNMP

PERL_CONFIGURE=	yes
USES=		perl5
USE_PERL5=	configure

NO_STAGE=	yes

post-install:
		@${INSTALL_DATA} ${WRKSRC}/README \
			${PREFIX}/lib/perl5/site_perl/README.SNMP

.include <bsd.port.mk>
