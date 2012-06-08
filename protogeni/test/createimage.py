#! /usr/bin/env python
#
# GENIPUBLIC-COPYRIGHT
# Copyright (c) 2008-2012 University of Utah and the Flux Group.
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

if len(REQARGS) != 2:
    Usage()
    sys.exit(1)
    pass

imagename  = REQARGS[0]
sliver_urn = REQARGS[1]

#
# Get a credential for myself, that allows me to do things at the SA.
#
mycredential = get_self_credential()
print "Got my SA credential"

#
# Lookup slice and get credential.
#
myslice = resolve_slice( SLICENAME, mycredential )

print "Asking for slice credential for " + SLICENAME
slicecredential = get_slice_credential( myslice, mycredential )
print "Got the slice credential"

#
# Create the image
#
print "Creating the Image ..."
params = {}
params["credentials"] = (slicecredential,)
params["slice_urn"]   = myslice["urn"]
params["sliver_urn"]  = sliver_urn
params["imagename"]   = imagename
rval,response = do_method("cm", "CreateImage", params, version="2.0")
if rval:
    Fatal("Could not create image")
    pass
imageurn = response["value"]
output = response["output"]
print str(imageurn)
print str(output)

