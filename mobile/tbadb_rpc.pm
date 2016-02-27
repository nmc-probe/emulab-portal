#!/usr/bin/perl -w

#
# Copyright (c) 2016 University of Utah and the Flux Group.
# 
# {{{EMULAB-LICENSE
# 
# This file is part of the Emulab network testbed software.
# 
# This file is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
# 
# }}}
#

package tbadb_rpc;
use Exporter;

@ISA = "Exporter";
@EXPORT =
    qw ( RPCERR_BADARGS RPCERR_BADFUNC RPCERR_NOTIMPL RPCERR_INTERNAL );

use strict;
use English;

sub RPCERR_BADARGS  { return 2; }
sub RPCERR_BADFUNC  { return 3; }
sub RPCERR_NOTIMPL  { return 4; }
sub RPCERR_INTERNAL { return 13; }


# End with "true"
1;
