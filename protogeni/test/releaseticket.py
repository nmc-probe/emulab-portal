#! /usr/bin/env python
#
# Copyright (c) 2008-2013 University of Utah and the Flux Group.
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

debug    = 0
impotent = 1

execfile( "test-common.py" )

#
# Get a credential for myself, that allows me to do things at the SA.
#
mycredential = get_self_credential()
print "Got my SA credential"

#
# Lookup slice and get credential.
#
myslice = resolve_slice( SLICENAME, mycredential )

#
# Get the slice credential.
#
print "Asking for slice credential for " + SLICENAME
slicecred = get_slice_credential( myslice, mycredential )
print "Got the slice credential"

#
# Do a resolve to get the ticket urn.
#
print "Resolving the slice at the CM"
params = {}
params["credentials"] = (slicecred,)
params["urn"]         = myslice["urn"]
rval,response = do_method("cm", "Resolve", params, version="2.0")
if rval:
    Fatal("Could not resolve slice")
    pass
myslice = response["value"]
print str(myslice)

if not "ticket_urn" in myslice:
    Fatal("No ticket exists for slice")
    pass

#
# Get the ticket with another call to resolve.
#
print "Asking for the ticket"
params = {}
params["credentials"] = (slicecred,)
params["urn"]         = myslice["ticket_urn"]
rval,response = do_method("cm", "Resolve", params, version="2.0")
if rval:
    Fatal("Could not get the ticket")
    pass
ticket = response["value"]
print "Got the ticket"

#
# And release the ticket.
#
print "Releasing the ticket"
params = {}
params["slice_urn"]   = myslice["urn"]
params["credentials"] = (slicecred,)
params["ticket"]      = ticket
rval,response = do_method("cm", "ReleaseTicket", params, version="2.0")
if rval:
    Fatal("Could not release the ticket")
    pass
print "The ticket has been released"

