/* 
 * Copyright (c) 2000 The University of Utah and the Flux Group.
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute this software is hereby
 * granted provided that (1) source code retains these copyright, permission,
 * and disclaimer notices, and (2) redistributions including binaries
 * reproduce the notices in supporting documentation.
 *
 * THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
 * FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 * 
 * ---------------------------
 *
 * Filename: forw_requests.c
 *   -- Author: Kristin Wright <kwright@cs.utah.edu> 
 *
 * ---------------------------
 *
 * $Id: forw_requests.c,v 1.6 2001-06-14 23:19:23 ikumar Exp $
 */

#include <math.h>

#include "discvr.h"
#include "packet.h"
#include "util.h"

/*
 * Send a request on to each interface 
 */
char recvbuf[BUFSIZ];

static double start = 0.0;

double
tod(void)
{
        double s;
	struct timeval tv;

	gettimeofday(&tv, 0);
	s = tv.tv_sec;
	s += (1e-6 * tv.tv_usec);
	return (s - start);
}


struct ifi_info *
forward_request(struct ifi_info *ifi, const struct in_pktinfo *pktinfo, 
		 const char *mesg, int mesglen) 
{
	int                     s, n;
	int                     more_time = 1;
	fd_set                  rset;
        const int               on = 1;
	char                    ifname[IFNAMSIZ];
	struct topd_inqid       *tdi;
	struct topd_nborlist    *save;
	struct sockaddr_in      sin,tempAddr;
	struct ifi_info         *ifihead;
	struct timeval          tv;
	int selectReturn;
	struct sockaddr         name;
        int                     namelen=sizeof(name);

	printf("The interface on which I received: \"%s\"\n",if_indextoname(pktinfo->ipi_ifindex, ifname));
	
	for (ifihead = ifi = get_ifi_info(AF_INET, 0); 
	     ifi != NULL; ifi = ifi->ifi_next) {
	  
	        /* 
		 * Don't send a message if the interface is down,
		 * a loopback interface, or it's the receiving
		 * interface.
		 * 
		 * Add check for control net? -lkw
		 */


	        if ((ifi->ifi_flags & !IFF_UP) || 
		    (ifi->ifi_flags & IFF_LOOPBACK) ||
		    (strcmp(ifi->ifi_name, if_indextoname(pktinfo->ipi_ifindex, ifname)) == 0)) {
		  ifi->ifi_myflags |= MY_IFF_RECVIF; /* may be unnec. -lkw */
		        continue;
		}
		
		// Adding check for control net... -ik
		if(strcmp(ifi->ifi_name,"fxp4")==0) continue;
		
		printf("Forwarding the query to interface: \"%s\"\n",ifi->ifi_name);

		bzero(&tempAddr, sizeof(tempAddr));
	        tempAddr.sin_family      = AF_INET;
        	//inet_aton("192.168.2.2",&tempAddr.sin_addr.s_addr);
		tempAddr.sin_addr.s_addr = htonl(INADDR_ANY);
        	tempAddr.sin_port        = htons(0);


	        s = socket(AF_INET, SOCK_DGRAM, 0);
	        if (s == -1) {
		        perror("Unable to get socket");
			exit(1);
		}
		if(bind(s, (struct sockaddr *) &tempAddr, sizeof(tempAddr))<0)
	        {
               		perror("bind");
        	}

		if (setsockopt(s, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on)) != 0) {
		        perror("setsockopt died.");
			/* Do something intelligent. -lkw */
		} 

		bzero(&sin, sizeof(sin));
		sin.sin_len = htons(sizeof sin);
		sin.sin_family = PF_INET;
		sin.sin_port = htons(SERV_PORT);
		/* sin.sin_addr.s_addr = inet_addr(BROADCAST_IP); */
		/* 
		 * struct sockaddr_in sin 
		 *   -> struct in_addr sin_addr
		 *      -> u_int32_t s_addr
		 *
		 * struct sockaddr *ifi_brdaddr
		 *  -> ifi_brdaddr->sa_data
		 */
		/*sin.sin_addr.s_addr = inet_addr(ifi->ifi_brdaddr->sa_data); */
		sin.sin_addr = ((struct sockaddr_in *)(ifi->ifi_brdaddr))->sin_addr; 
		printf("The dest. address: %s\n", inet_ntoa(sin.sin_addr));
		/* 
		 * though sendto() returns the correct number of bytes, 
		 * tcpdump is showing two packets for this one line. -lkw 
		 * 
		 *   60 eureka:testbed/discvr> tcpdump port 9877
		 *   tcpdump: listening on fxp0
		 *   15:04:59.357514 eureka.cs.utah.edu.1192 > 155.99.212.255.9877: udp 15
		 *   15:04:59.357528 eureka.cs.utah.edu.1192 > 155.99.212.255.9877: udp 15
		 *   15:20:02.075858 kamas.cs.utah.edu.9877 > eureka.cs.utah.edu.1214: udp 15
		 */
		fprintf(stderr, "$$$forwarding the enquiry: ");
		print_tdinq(mesg);
		n = sendto(s, mesg, mesglen, 0, 
			   (struct sockaddr *)&sin, sizeof(struct sockaddr_in));
		fprintf(stderr, "$$$after forwarding the enquiry: ");
		print_tdinq(mesg);

		if(getsockname(s, (struct sockaddr *)&name, &namelen)<0)
	        {
        	        perror("getsockname\n");
        	}
	
	
		printf("The address from where i am sending: %s\n",sock_ntop(&name,name.sa_len));
		if (n != mesglen) {
		        perror("Didn't send all of packet");
			exit(1);
		} 

		/*
		 * Can't wait forever because
		 * there may be either no nodes on this interface or 
		 * the nodes that are there may not be responding. 
		 * Our wait delay is equal to the "factor times the ttl". 
		 *
		 * The packet size *might* exceed our buffer size. 
		 * Put in some mechanism to check. -lkw
		 */

		tdi = (struct topd_inqid *)mesg;
		tv.tv_sec  = ntohs(tdi->tdi_ttl) * ntohs(tdi->tdi_factor);
		tv.tv_usec = 0;
		FD_ZERO(&rset);
		FD_SET(s, &rset);

		n     = 0;
                start = tod();
		while (	more_time  ) {
		        double begin, end, elapsed;
			double deadline = tv.tv_sec + (tv.tv_usec * 1e-6);

		        /* 
			 * It's possible that one neighbor responded very quickly
			 * and other neighbors (perhaps because they have many more
			 * neighbors whose messages they had to parse) could respond
			 * slowly. To cover this case, we should continue to try to 
			 * read from the socket until our delay is up. -lkw
			 */
		        begin = tod();
			
			printf("entering select for %d, max = %d****\n", s, FD_SETSIZE);
			selectReturn = select(FD_SETSIZE, &rset, NULL, NULL, &tv);
		        if( selectReturn < 0 ) {
				 printf("Error in Select call\n");
                                 perror("select");
				 exit(1);
                        }
			else if(selectReturn == 0)
			{
				printf("Select timed out****\n");
			}
			end = tod();
		
			if (!FD_ISSET(s, &rset)) {
			     /* socket is not readable */
			        fprintf(stderr, "Socket not readable before timeout.\n");
				more_time = 0;
				/*continue; */
			}
			
			/* get ready for next select */
			elapsed = end - begin;
			/* fprintf(stderr, "elapsed:%f ", elapsed); DEBUG */
			if (elapsed > deadline) {
			        break;
			}	
			deadline -= elapsed;
			tv.tv_sec = floor(deadline);
			tv.tv_usec = (deadline - tv.tv_sec) * 1e+6;
			fprintf(stderr, "sec:%d usec:%d\n", tv.tv_sec, tv.tv_usec);

			// receive one of my neighbors' list of neighbors through 
			// "ifi" interface to which I just forwarded the request -ik
			n = recvfrom(s, recvbuf, BUFSIZ, 0, NULL, NULL);
			//printf ("recvd %d\n", n);
			printf ("received:==>\n");
			print_tdreply(recvbuf,n);
			
				
		        /* 
			 * Be sure to malloc enough space for all of the mesg. 
			 * See note above about possible datagram truncation. -lkw
			 */

			// save the existing list of neighbors which I just received through
			// the "ifi" interface... -ik
		    save = ifi->ifi_nbors;
			printf("The value of save: \"%d\"\n",save);

			// create a new node for the neighbor link list pointed by "ifi_nbors"
			// -ik
			ifi->ifi_nbors = (struct topd_nborlist *)malloc(sizeof(struct topd_nborlist)); 
			if ( ifi->ifi_nbors == NULL ) {
		                perror("Not enough memory for neighbor list.");
				exit(1);
			}
			/* skip inquiry ID */
			ifi->ifi_nbors->tdnbl_nbors = (u_char *)malloc(n);
			if ( ifi->ifi_nbors->tdnbl_nbors == NULL ) {
		                perror("Not enough memory for neighbor list.");
				exit(1);
			}
			
			// why "recvbuf +  sizeof(topd_inqid_t)" ?
			// Ans: The reason we skip this first "sizeof(topd_inqid_t)" is because 
			//      to every message there is a "inquiry ID" attached in the beginning... 
			// -ik
			//print_tdpairs(recvbuf + sizeof(topd_inqid_t),n-sizeof(topd_inqid_t));
			memcpy((void *)ifi->ifi_nbors->tdnbl_nbors, recvbuf + sizeof(topd_inqid_t), n);
			// The "tdnbl_n" contains the number of neighbors that the node, along this
			// interface, has ... -ik
			
			ifi->ifi_nbors->tdnbl_n = n / sizeof(struct topd_nbor);
			ifi->ifi_nbors->tdnbl_next = save;
			//print_tdpairs(ifi->ifi_nbors->tdnbl_nbors,n-sizeof(topd_inqid_t));
		}
	}
	print_tdifinbrs(ifihead);
	return ifihead;
}
