#!/bin/sh
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2012 University of Utah and the Flux Group.
# All rights reserved.
#

prefix=$1

#
# Sign the client cert request, creating a client certificate.
#
openssl ca -batch -policy policy_match -config ca.cnf \
	-out ${prefix}.pem \
        -cert emulab.pem -keyfile emulab.key \
	-infiles ${prefix}.req

#
# Combine the key and the certificate into one file which is installed
# on each remote node and used by tmcc. Installed on boss too so
# we can test tmcc there.
#
cat ${prefix}.key >> ${prefix}.pem

exit 0
