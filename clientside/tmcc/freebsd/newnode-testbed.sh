#!/bin/sh
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2012 University of Utah and the Flux Group.
# All rights reserved.
#
# PROVIDE: testbed
# REQUIRE: sshd
#

. /etc/emulab/paths.sh

#
# Boottime initialization. 
#
case "$1" in
start|faststart)
	echo ""
	$BINDIR/newclient
	;;
stop)
	# Foreground mode.
	;;
*)
	echo "Usage: `basename $0` {start|stop}" >&2
	;;
esac

exit 0
