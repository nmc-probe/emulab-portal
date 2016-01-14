# Created by: Gary Wong <gtw@flux.utah.edu>

PORTNAME=	abac
PORTVERSION=	0.1.9
CATEGORIES=	misc
MASTER_SITES=	http://abac.deterlab.net/src/

MAINTAINER=	testbed-ops@flux.utah.edu
COMMENT=	"Attribute-Based Access Control library, as adopted by GENI"

GNU_CONFIGURE=	yes
USES=		gettext gmake libtool
CPPFLAGS+=	-I${LOCALBASE}/include
LDFLAGS+=	-L${LOCALBASE}/lib

.include <bsd.port.mk>
