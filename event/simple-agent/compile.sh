#
# EMULAB-COPYRIGHT
# Copyright (c) 2010 University of Utah and the Flux Group.
# All rights reserved.
#
gcc  -c /proj/utahstud/ydev/emulab-devel/clientside/lib/event/event.c -o event.o -I/proj/utahstud/ydev/emulab-devel/clientside/lib \
-I /proj/utahstud/ydev/emulab-devel/clientside/lib/libtb -I/proj/utahstud/ydev/ -L/proj/utahstud/ydev/pubsub
gcc  -c /proj/utahstud/ydev/emulab-devel/clientside/lib/event/util.c -o util.o -I/proj/utahstud/ydev/emulab-devel/clientside/lib \
-I /proj/utahstud/ydev/emulab-devel/clientside/lib/libtb -I/proj/utahstud/ydev/ -L/proj/utahstud/ydev/pubsub
ar crv libevent.a event.o util.o
ranlib libevent.a
g++  -g -o disk-agent -Wall -I/proj/utahstud/ydev/emulab-devel/clientside/lib -I/proj/utahstud/ydev/emulab-devel/clientside/lib/libtb \
  -I/proj/utahstud/ydev/emulab-devel/event/simple-agent -L/proj/utahstud/ydev/emulab-devel/event/simple-agent -L/proj/utahstud/ydev/pubsub disk-agent.cc libevent.a -ldevmapper -lpubsub -lssl

