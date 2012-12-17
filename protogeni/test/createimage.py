#! /usr/bin/env python
#
# Copyright (c) 2008-2012 University of Utah and the Flux Group.
# 
# {{{GENIPUBLIC-LICENSE
# 
# GENI Public License
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and/or hardware specification (the "Work") to
# deal in the Work without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Work, and to permit persons to whom the Work
# is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Work.
# 
# THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
# IN THE WORK.
# 
# }}}
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

def Usage():
    print "usage: " + sys.argv[ 0 ] + " [option...] imagename sliver-urn [global]"
    print """Options:
    -c file, --credentials=file         read self-credentials from file
                                            [default: query from SA]
    -d, --debug                         be verbose about XML methods invoked
    -f file, --certificate=file         read SSL certificate from file
                                            [default: ~/.ssl/encrypted.pem]
    -h, --help                          show options and usage
    -l uri, --sa=uri                    specify uri of slice authority
                                            [default: local]
    -m uri, --cm=uri                    specify uri of component manager
                                            [default: local]
    -n name, --slicename=name           specify human-readable name of slice
                                            [default: mytestslice]
    -p file, --passphrase=file          read passphrase from file
                                            [default: ~/.ssl/password]
    -r file, --read-commands=file       specify additional configuration file
    -s file, --slicecredentials=file    read slice credentials from file
                                            [default: query from SA]"""

debug    = 0
impotent = 1
doglobal = 1

execfile( "test-common.py" )

if len(REQARGS) < 2 or len(REQARGS) > 3:
    Usage()
    sys.exit(1)
    pass

imagename  = REQARGS[0]
sliver_urn = REQARGS[1]

if len(REQARGS) == 3:
    doglobal = REQARGS[2]
    pass

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
params["global"]      = doglobal
rval,response = do_method("cm", "CreateImage", params, version="2.0")
if rval:
    Fatal("Could not create image")
    pass
imageurn = response["value"]
output = response["output"]
print str(imageurn)
print str(output)

