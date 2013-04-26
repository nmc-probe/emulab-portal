#!/usr/bin/perl -d:Trace
#
# Copyright (c) 2013 University of Utah and the Flux Group.
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
use English;
use Getopt::Std;
use strict;


BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }
use libtestbed;

sub usage()
{
        print STDOUT "Usage: generate-export.pl <outfile> <out_file>";
            exit(-1);
}

if (@ARGV != 2){
        usage();
}

my $osid = $ARGV[0];
$osid =~ "s/\//\\\/g";

my $out = `who`;
my ($user) = split /\s+/, $out;
#TODO: Depends on who is running this script on ops...runasuser() thingy???


#TODO - find the correct ops node and pull in and shit from some sane config
system("sed 's/~~SERVER~~/myops.metadata.utahstud.emulab.net/' < export-template.rb | sed 's/~~IN_DIR~~/\\/q\\/indir\\//' | sed 's/~~IN_FILE~~/$osid/' | sed 's/~~USER~~/$user/' > $ARGV[1]");}
