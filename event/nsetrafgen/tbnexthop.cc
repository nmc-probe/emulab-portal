#include <stdio.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/route.h>
#include <netinet/in.h>
#include <net/if_dl.h>
#include <unistd.h>
#include "tbnexthop.h"

static int sockfd;
static char buf[512];
static pid_t mypid = 0;
static int myseq;

#define ROUNDUP(a) \
	((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

uint16_t
get_nexthop_if(struct in_addr addr)
{
	struct rt_msghdr *rtm;
	struct sockaddr_dl *ifp;
	struct sockaddr_in *sin;
	struct sockaddr *sa;
	int i, len;

	if (mypid == 0) {
		mypid = getpid();
		sockfd = socket(AF_ROUTE, SOCK_RAW, 0);
		if (sockfd < 0) {
			perror("AF_ROUTE");
			exit(1);
		}
	}

	rtm = (struct rt_msghdr *) buf;
	rtm->rtm_msglen = sizeof(struct rt_msghdr) +
		ROUNDUP(sizeof(*sin)) + ROUNDUP(sizeof(*ifp));
	rtm->rtm_version = RTM_VERSION;
	rtm->rtm_type = RTM_GET;
	rtm->rtm_addrs = RTA_DST|RTA_IFP;
	rtm->rtm_pid = mypid;
	rtm->rtm_seq = ++myseq;
	rtm->rtm_flags = RTF_UP|RTF_HOST|RTF_GATEWAY|RTF_STATIC;

	sin = (struct sockaddr_in *)&rtm[1];
	sin->sin_family = AF_INET;
	sin->sin_len = sizeof(struct sockaddr_in);
	sin->sin_addr = addr;

	ifp = (struct sockaddr_dl *)((char *)sin + ROUNDUP(sizeof(*sin)));
	ifp->sdl_len = sizeof(struct sockaddr_dl);
	ifp->sdl_family = AF_LINK;

	if (write(sockfd, rtm, rtm->rtm_msglen) < 0) {
		perror("write");
		exit(3);
	}

	do {
		if (read(sockfd, rtm, sizeof(buf)) < 0) {
			perror("read");
			exit(3);
		}
	} while (rtm->rtm_type != RTM_GET ||
		 rtm->rtm_seq != myseq || rtm->rtm_pid != mypid);

	if (rtm->rtm_version != RTM_VERSION) {
		fprintf(stderr, "wrong version of routing code (%d != %d)\n",
			rtm->rtm_version, RTM_VERSION);
		exit(3);
	}
	if (rtm->rtm_errno) {
		fprintf(stderr, "route read returns error %d\n",
			rtm->rtm_errno);
		exit(3);
	}

	if ((rtm->rtm_addrs & RTA_IFP) == 0)
		return 0;

	sa = (struct sockaddr *)&rtm[1];
	for (i = 1; i != 0; i <<= 1) {
		len = ROUNDUP(sa->sa_len);
		switch (i & rtm->rtm_addrs) {
		case 0:
			break;
		case RTA_IFP:
			if (sa->sa_family == AF_LINK) {
				ifp = (struct sockaddr_dl *)sa;
				return ifp->sdl_index;
			}
			/* fall into ... */
		default:
			sa = (struct sockaddr *)((char *)sa + len);
			break;
		}
	}

	return 0;
}

#ifdef TBNEXTHOP_TESTME
int
main(int argc, char **argv)
{
	struct in_addr addr;
	int ifn;

	if (argc < 2) {
		fprintf(stderr, "usage: %s IPaddr ...\n", argv[0]);
		exit(2);
	}

	while (*++argv != 0) {
		if (inet_aton(*argv, &addr) == 0) {
			fprintf(stderr, "bad IP address: %s\n", *argv);
			exit(2);
		}

		ifn = get_nexthop_if(&addr);
		if (ifn == 0)
			printf("%s: no route\n", *argv);
		else
			printf("%s: through if%d\n", *argv, ifn);
	}

	exit(0);
}
#endif
