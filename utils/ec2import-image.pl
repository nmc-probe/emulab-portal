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

# Drag in path stuff so we can find emulab stuff.
BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }

#
# Take a raw image and make a proper emulab image based off of it
#
sub usage()
{
    print STDOUT "Usage: ec2import-image remote-user remote-addr project user osid";
    exit(-1);
}
my  $optlist = "";

#
# Turn off line buffering on output
#
$| = 1;

# Need this for predicates.
use libsetup;


my $TB       = "/usr/testbed";
#
# No configure vars.
#
my $WORK_BASE  = "/q/import_temp/";
my $IN_BASE  = "/q/indir/";
#TODO something in some script that creates these two directorieso
my $TAR      = "tar";
my $sudo;
my $zipper   = "/usr/local/bin/imagezip";
my $uploader = "/usr/local/etc/emulab/frisupload";

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

if (@ARGV != 5) {
    usage();
}

my $remote = $ARGV[0];
my $project = $ARGV[1];
my $user = $ARGV[2];
my $osid = $ARGV[3];
my $outfile = $ARGV[4];

#my $ruser = split('@',$remote)[0];
#my $raddr = split('@',$remote)[1];

my $infile = $IN_BASE . $project . "/" . $user . "/" . $osid . ".tar.gz";
my $workdir = $WORK_BASE . $project . "/" . $user . "/" . $osid . "-tmp";

# Man, this really needs some exception handling
print $remote;
if(system("echo \"mkdir ~/.emulab\" | ssh $remote bash")){
    print STDERR "Couldn't mkdir ~/.emulab";
}

# Remotely execute the export script
if(system("scp $TB/sbin/export-template-remote.rb $remote:~/.emulab/export.rb")){
    print STDERR "Couldn't scp exporter script into $remote\n";
    goto cleanup;
}

#TODO Ruby prereq check
#TODO return 1 on fail


if(system("ssh $remote 'sudo ruby -C ~/.emulab < ~/.emulab/export.rb'")){
    print STDERR "Remote image creation failed\n";
    goto cleanup;
}

# SCP back the generated image file
# TODO Saner name for tar and .emulab?
if(system("scp $remote:~/.emulab/emulab.tar.gz $infile")){
    print STDERR "Couldn't scp image back into ops\n";
    goto cleanup;
}

# Process the tar blah image
if (! -e $infile){
    print STDERR "*** Input tar image not found.\n";
    print STDERR "Looking for:" . $infile . "\n";
    goto cleanup;
}

# Unzip into the working dir
if (system("mkdir -p $workdir")){
    print STDERR "Couldn't mkdir $workdir \n";
    goto cleanup;
}

if (system("tar -xvzf $infile -C $workdir")){
    print STDERR "Failed to extract $infile \n";
    goto cleanup;
}

my $filesize = ceil((-s "$workdir/image")/(1024*1024*1024));
$filesize = $filesize + 4;

# TODO: Proper xvda1 size based on image size?
# TODO: Maybe handle bootopts
# Create the "special" xm.conf
my $heredoc = <<XMCONF;
disksizes = 'xvda2:2.00g,xvda1:$filesize.00g'
memory = '256'
disk = ['phy:/dev/xen-vg/pcvm666-1,xvda1,w','phy:/dev/xen-vg/pcvm666.swap,xvda2,w']
kernel = 'kernel'
ramdisk = 'initrd'
vif = ['mac=02:bf:bb:b9:ae:9c, ip=172.19.140.1, bridge=xenbr0']
name = 'pcvm666-1'
extra = 'root=/dev/xvda1 boot_verbose=1 vfs.root.mountfrom=ufs:/dev/da0a kern.bootfile=/boot/kernel/kernel console=xvc0 selinux=0'
XMCONF

open(FH, '>', "$workdir/xm.conf") or goto cleanup;

print FH $heredoc;

close(FH);

# Image zip the raw image
if (system("$zipper -o -l $workdir/image $workdir/xvda1")) {
    print STDERR "*** Failed to greate image!\n";
    print STDERR "    command: $zipper -o -l $workdir/image $workdir/xvda1\n";
}


# Tar everything up and then imagezip
my $cmd = "$TAR zcf - -C $workdir xvda1 xm.conf kernel initrd | $zipper -f - $outfile";

if (system("$cmd")) {
    print STDERR "*** Failed to create image!\n";
    print STDERR "    command: '$cmd'\n";
    goto cleanup;
}

cleanup:
# Clean up the directory.
print STDOUT "Performing cleanup...\n";
system("$sudo /bin/rm -rf $workdir 2>/dev/null");
system("echo 'rm -Rf ~/.emulab' | ssh $remote bash");
