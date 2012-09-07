#! /usr/bin/env python
#
# GENIPUBLIC-COPYRIGHT
# Copyright (c) 2012 University of Utah and the Flux Group.
# All rights reserved.
# 
# Permission to use, copy, modify and distribute this software is hereby
# granted provided that (1) source code retains these copyright, permission,
# and disclaimer notices, and (2) redistributions including binaries
# reproduce the notices in supporting documentation.
#
# THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
# CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
# FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
#

#
#
import sys
import pwd
import getopt
import os
import time
import re

ACCEPTSLICENAME=1

debug    = 0
impotent = 1

execfile( "test-common.py" )

action = "geni_start"

if len(REQARGS) != 1:
    Usage()
    sys.exit( 1 )
elif len(REQARGS) == 1:
    action = REQARGS[0]

if action != "geni_start" and action != "geni_stop" and action != "geni_restart":
   Fatal("Invalid action. Must be one of: geni_start geni_stop geni_restart");

#
# Get a credential for myself, that allows me to do things at the SA.
#
mycredential = get_self_credential()
print "Got my SA credential"

#
# Lookup slice.
#
params = {}
params["credential"] = mycredential
params["type"]       = "Slice"
params["hrn"]        = SLICENAME
rval,response = do_method("sa", "Resolve", params)
if rval:
    Fatal("No such slice exists")
else:
    #
    # Get the slice credential.
    #
    print "Asking for slice credential for " + SLICENAME
    myslice = response["value"]
    myslice = get_slice_credential( myslice, mycredential )
    print "Got the slice credential"
    pass

#
# Perform operational action on the sliver
#
print "Performing Operational Action " + action + " ..."
options = {}
cred = {}
cred["geni_type"] = "geni_sfa"
cred["geni_version"] = "2"
cred["geni_value"] = myslice
params = [[SLICEURN], [cred], action, options]

try:
    response = do_method("am/3.0", "PerformOperationalAction", params,
                         response_handler=geni_am_response_handler)
    print action + "'d the sliver"
    print str(response)
except xmlrpclib.Fault, e:
    Fatal("Could not perform action on sliver: %s" % (str(e)))
