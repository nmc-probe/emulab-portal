/*
 * EMULAB-COPYRIGHT
 * Copyright (c) 2002 University of Utah and the Flux Group.
 * All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "decls.h"
#include "trace.h"
#include "log.h"

#ifdef NEVENTS

struct event eventlog[NEVENTS];
struct event *evptr = eventlog;
struct event *evend = &eventlog[NEVENTS];
int evlogging, evcount;
pthread_mutex_t evlock;
static int evisclient;
static FILE *fd;
static struct timeval startt;

static void
TraceInit(char *file)
{
	static int called;

	if (file) {
		fd = fopen(file, "a+");
		if (fd == NULL)
			pfatal("Cannot open logfile %s", file);
	} else
		fd = stderr;

	if (!called) {
		called = 1;
		pthread_mutex_init(&evlock, 0);
	}
}

void
ClientTraceInit(char *prefix)
{
	extern struct in_addr myipaddr;

	evlogging = 0;

	if (fd != NULL && fd != stderr)
		fclose(fd);
	memset(eventlog, 0, sizeof eventlog);
	evptr = eventlog;
	evcount = 0;

	if (prefix && prefix[0]) {
		char name[64];
		snprintf(name, sizeof(name),
			 "%s-%s.trace", prefix, inet_ntoa(myipaddr));
		TraceInit(name);
	} else
		TraceInit(0);

	evisclient = 1;
}

void
ServerTraceInit(char *file)
{
	extern struct in_addr myipaddr;

	if (file) {
		char name[64];
		snprintf(name, sizeof(name),
			 "%s-%s.trace", file, inet_ntoa(myipaddr));
		TraceInit(name);
	} else
		TraceInit(0);

	evisclient = 0;
}

void
TraceStart(int level)
{
	evlogging = level;
	gettimeofday(&startt, 0);
}

void
TraceStop(void)
{
	evlogging = 0;
}

void
TraceDump(void)
{
	struct event *ptr;
	int done = 0;
	struct timeval stamp;
	int oevlogging = evlogging;

	evlogging = 0;
	ptr = evptr;
	do {
		if (ptr->event > 0 && ptr->event <= EV_MAX) {
			if (!done) {
				done = 1;
				fprintf(fd, "%d of %d events, "
					"start: %ld.%03ld:\n",
					evcount > NEVENTS ? NEVENTS : evcount,
					evcount, (long)startt.tv_sec,
					startt.tv_usec/1000);
			}
			timersub(&ptr->tstamp, &startt, &stamp);
			fprintf(fd, " +%03ld.%03ld: ",
				(long)stamp.tv_sec, stamp.tv_usec/1000);
			switch (ptr->event) {
			case EV_JOINREQ:
				fprintf(fd, "%s: JOIN request, ID=%lx\n",
					inet_ntoa(ptr->srcip), ptr->args[0]);
				break;
			case EV_JOINREP:
				fprintf(fd, "%s: JOIN reply, blocks=%lu\n",
					inet_ntoa(ptr->srcip), ptr->args[0]);
				break;
			case EV_LEAVEMSG:
				fprintf(fd, "%s: LEAVE msg, ID=%lx, time=%lu\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_REQMSG:
				fprintf(fd, "%s: REQUEST msg, %lu[%lu-%lu]\n",
					inet_ntoa(ptr->srcip), 
					ptr->args[0], ptr->args[1],
					ptr->args[1]+ptr->args[2]-1);
				break;
			case EV_BLOCKMSG:
				fprintf(fd, "send block, %lu[%lu]\n",
					ptr->args[0], ptr->args[1]);
				break;
			case EV_WORKENQ:
				fprintf(fd, "enqueues, %lu[%lu-%lu], "
					"%lu ents\n",
					ptr->args[0], ptr->args[1],
					ptr->args[1]+ptr->args[2]-1,
					ptr->args[3]);
				break;
			case EV_WORKDEQ:
				fprintf(fd, "dequeues, %lu[%lu-%lu], "
					"%lu ents\n",
					ptr->args[0], ptr->args[1],
					ptr->args[1]+ptr->args[2]-1,
					ptr->args[3]);
				break;
			case EV_WORKOVERLAP:
				fprintf(fd, "queue overlap, "
					"old=[%lu-%lu], new=[%lu-%lu]\n",
					ptr->args[0],
					ptr->args[0]+ptr->args[1]-1,
					ptr->args[2],
					ptr->args[2]+ptr->args[3]-1);
				break;
			case EV_WORKMERGE:
				fprintf(fd, "modqueue, %lu[%lu-%lu] "
					"at ent %lu\n",
					ptr->args[0], ptr->args[1],
					ptr->args[1]+ptr->args[2]-1,
					ptr->args[3]);
				break;
			case EV_READFILE:
				fprintf(fd, "readfile, %lu@%lu -> %lu\n",
					ptr->args[1],
					ptr->args[0], ptr->args[2]);
				break;


			case EV_CLISTART:
				fprintf(fd, "%s: starting\n",
					inet_ntoa(ptr->srcip));
				break;
			case EV_OCLIMSG:
			{
				struct in_addr ipaddr = { ptr->args[0] };

				fprintf(fd, "%s: got %s msg, ",
					inet_ntoa(ptr->srcip),
					(ptr->args[1] == PKTSUBTYPE_JOIN ?
					 "JOIN" : "LEAVE"));
				fprintf(fd, "ip=%s\n", inet_ntoa(ipaddr));
				break;
			}
			case EV_CLIREQMSG:
			{
				struct in_addr ipaddr = { ptr->args[0] };

				fprintf(fd, "%s: saw REQUEST for ",
					inet_ntoa(ptr->srcip));
				fprintf(fd, "%lu[%lu-%lu], ip=%s\n",
					ptr->args[1], ptr->args[2],
					ptr->args[2]+ptr->args[3]-1,
					inet_ntoa(ipaddr));
				break;
			}
			case EV_CLINOROOM:
				fprintf(fd, "%s: block %lu[%lu], no room\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_CLIDUPCHUNK:
				fprintf(fd, "%s: block %lu[%lu], dup chunk\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_CLIDUPBLOCK:
				fprintf(fd, "%s: block %lu[%lu], dup block\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_CLIBLOCK:
				fprintf(fd, "%s: block %lu[%lu], remaining=%lu\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1],
					ptr->args[2]);
				break;
			case EV_CLISCHUNK:
				fprintf(fd, "%s: start chunk %lu, block %lu\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_CLIECHUNK:
				fprintf(fd, "%s: end chunk %lu, block %lu\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_CLIREQ:
				fprintf(fd, "%s: send REQUEST, %lu[%lu-%lu]\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1],
					ptr->args[1]+ptr->args[2]-1);
				break;
			case EV_CLIREQCHUNK:
				fprintf(fd, "%s: request chunk, timeo=%lu\n",
					inet_ntoa(ptr->srcip), ptr->args[0]);
				break;
			case EV_CLIJOINREQ:
				fprintf(fd, "%s: send JOIN, ID=%lx\n",
					inet_ntoa(ptr->srcip), ptr->args[0]);
				break;
			case EV_CLIJOINREP:
				fprintf(fd, "%s: got JOIN reply, blocks=%lu\n",
					inet_ntoa(ptr->srcip), ptr->args[0]);
				break;
			case EV_CLILEAVE:
				fprintf(fd, "%s: send LEAVE, ID=%lx, time=%lu\n",
					inet_ntoa(ptr->srcip),
					ptr->args[0], ptr->args[1]);
				break;
			case EV_CLISTAMP:
				fprintf(fd, "%s: update chunk %lu, stamp %lu.%06lu\n",
					inet_ntoa(ptr->srcip), ptr->args[0],
					ptr->args[1], ptr->args[2]);
				break;
			case EV_CLIWRDONE:
				fprintf(fd, "%s: chunk %lu written, %lu left\n",
					inet_ntoa(ptr->srcip), ptr->args[0],
					ptr->args[1]);
				break;
			case EV_CLIWRIDLE:
				fprintf(fd, "%s: IDLE\n",
					inet_ntoa(ptr->srcip));
				break;
			case EV_CLIGOTPKT:
				stamp.tv_sec = ptr->args[0];
				stamp.tv_usec = ptr->args[1];
				timersub(&ptr->tstamp, &stamp, &stamp);
				fprintf(fd, "%s: got block, wait=%03ld.%03ld\n",
					inet_ntoa(ptr->srcip),
					stamp.tv_sec, stamp.tv_usec/1000);
				break;
			case EV_CLIRTIMO:
				stamp.tv_sec = ptr->args[0];
				stamp.tv_usec = ptr->args[1];
				timersub(&ptr->tstamp, &stamp, &stamp);
				fprintf(fd, "%s: recv timeout, wait=%03ld.%03ld\n",
					inet_ntoa(ptr->srcip),
					stamp.tv_sec, stamp.tv_usec/1000);
				break;
			}
		}
		if (++ptr == evend)
			ptr = eventlog;
	} while (ptr != evptr);
	fflush(fd);
	evlogging = oevlogging;
}
#endif
