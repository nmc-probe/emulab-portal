#!/bin/sh
#
# EMULAB-COPYRIGHT
# Copyright (c) 2010, University of Utah and the Flux Group.
# All rights reserved.
#

iperfd/iperfd -s -p 4242 &
sudo libnetmon/instrument-standalone.sh magent/magent --interface=vnet --replay-save=/local/logs/stub.replay --monitorserverport=3153 --peerserverport=4242 --peerudpserverport=4243 1> /local/logs/stub.out 2> /local/logs/stub.err


