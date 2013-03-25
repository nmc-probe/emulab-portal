#!/usr/bin/perl -d:Trace                                                                                                                                                                                                                                               [78/1805]
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

# Drag in path stuff so we can find emulab stuff.
BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }

my $EXTRAFS     = "/q/image-import";
my $TAR         = "tar";

#
# Take a raw image and make a proper emulab image based off of it
#
sub usage()
{
    print STDOUT "Usage: create-_ndz ".  "<filename>\n";
    exit(-1);
}
my  $optlist = "";

#
# Turn off line buffering on output
#
$| = 1;

# Need this for predicates.
use libsetup;

#
# No configure vars.
#
my $sudo;
my $zipper   = "/usr/local/bin/imagezip";
my $uploader = "/usr/local/etc/emulab/frisupload";
my $filename = "blah-uniqid.ndz";
my $iserver;
my $imageid;
my $error    = 0;

for my $path (qw#/usr/local/bin /usr/bin#) {
        if (-e "$path/sudo") {
                $sudo = "$path/sudo";
                last;
        }
}

#
# Parse command arguments. Once we return from getopts, all that should be
# left are the required arguments.
#
my %options = ();
if (! getopts($optlist, \%options)) {
    usage();
}
if (@ARGV != 2) {
    usage();
}

my $hostaddress = $ARGV[0];
my $emulabtar = $ARGV[1];

#
# Untaint the arguments.
#
# Note different taint check (allow /).
#TODO UNTAINT

# SCP the in
# TODO: somefile that don't exist
print "$sudo scp -l ec2-user $hostaddress:$emulabtar $EXTRAFS/blah-uniqid.tar\n";
system("$sudo scp -i vhost-import ec2-user\@$hostaddress:$emulabtar $EXTRAFS/blah-uniqid.tar");


system("$sudo mkdir $EXTRAFS/blah-uniqid/");
# Unzip the thingy into extrafs
system("$sudo tar -xvzf $EXTRAFS/blah-uniqid.tar -C $EXTRAFS/blah-uniqid/");



# TODO: Proper sda size based on image size
# TODO: Maybe handle bootopts
# Create the "special" xm.conf
my $heredoc = <<XMCONF;
disksizes = 'sdb:2.00g,sda:12.00g'
memory = '256'
disk = ['phy:/dev/xen-vg/pcvm666-1,sda,w','phy:/dev/xen-vg/pcvm666.swap,sdb,w']
kernel = 'kernel'
ramdisk = 'initrd'
vif = ['mac=02:bf:bb:b9:ae:9c, ip=172.19.140.1, bridge=xenbr0']
name = 'pcvm666-1'
extra = 'root=/dev/sda boot_verbose=1 vfs.root.mountfrom=ufs:/dev/da0a kern.bootfile=/boot/kernel/kernel console=xvc0 selinux=0'
XMCONF

open(FH, '>', "$EXTRAFS/blah-uniqid/xm.conf") or goto cleanup;

print FH $heredoc;

close(FH);

# Image zip the raw image
if (system(("$sudo $zipper -o -l $EXTRAFS/blah-uniqid/tmp/image $EXTRAFS/blah-uniqid/sda"))) {
    print STDERR "*** Failed to create image!\n";
    print STDERR "    command: '$sudo \n";
    $error = 1;
}


# Tar everything up and then imagezip
my $cmd = "$TAR zcf - -C $EXTRAFS/blah-uniqid sda xm.conf kernel initrd | $zipper -f - $filename.ndz";

if (system("$sudo $cmd")) {
    print STDERR "*** Failed to create image!\n";
    print STDERR "    command: '$sudo $cmd'\n";
    $error = 1;
}

cleanup:
# Clean up the directory.
system("$sudo /bin/rm -rf $EXTRAFS/blah-uniqid");
