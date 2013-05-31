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
use POSIX;

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

# Check if we can connect to the machine using publickey only
if(system("ssh -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no" .
        " -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" .
        " -o ChallengeResponseAuthentication=no $remote 'exit'")){
    print STDERR "*** Couldn't connect to $remote\n";
    print STDERR "    Ensure that Emulabs public key is in the authorized_hosts\n";
    print STDERR "    command: ssh -o PasswordAuthentication=no" .
        " -o KbdInteractiveAuthentication=no" .
        " -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" .
        " -o ChallengeResponseAuthentication=no $remote 'exit'";
    $error = 1;
    goto cleanup;
}

if(system("echo \"mkdir -p ~/.emulab\" | ssh -o UserKnownHostsFile=/dev/null ".
        "-o StrictHostKeyChecking=no $remote bash")){
    print STDERR "*** Couldn't mkdir ~/.emulab";
    $error = 1;
    goto cleanup;
}

# Remotely execute the export script
if(system("scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ".
        "$TB/sbin/export-template-remote.rb $remote:~/.emulab/export.rb")){
    print STDERR "*** Couldn't scp exporter script into $remote\n";
    $error = 1;
    goto cleanup;
}

# Check if Ruby exists
if(system("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ".
        "$remote 'which ruby'")){
    print STDERR "*** Could not find ruby on remote machine!";
    $error = 1;
    goto cleanup;
}

if(system("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ".
        "-t -t $remote 'sudo ruby -C ~/.emulab < ~/.emulab/export.rb'")){
    print STDERR "*** Remote image creation failed\n";
    $error = 1;
    goto cleanup;
}

# SCP back the generated image file
# TODO Saner name for tar and .emulab?
if(system("scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ".
        "$remote:~/.emulab/emulab.tar.gz $infile")){
    print STDERR "*** Couldn't scp image back into ops\n";
    $error = 1;
    goto cleanup;
}

# Process the tar blah image
if (! -e $infile){
    print STDERR "*** Input tar image not found.\n";
    print STDERR "    Looking for:" . $infile . "\n";
    $error = 1;
    goto cleanup;
}

# Unzip into the working dir
if (system("mkdir -p $workdir")){
    print STDERR "*** Couldn't mkdir $workdir \n";
    $error = 1;
    goto cleanup;
}

if (system("tar -xvzf $infile -C $workdir")){
    print STDERR "*** Failed to extract $infile \n";
    $error = 1;
    goto cleanup;
}

my $filesize = ceil((-s "$workdir/emulab-image")/(1024*1024*1024));
$filesize = $filesize + 4;

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
if (system("$zipper -o -l $workdir/emulab-image $workdir/xvda1")) {
    print STDERR "*** Failed to greate image!\n";
    print STDERR "    command: $zipper -o -l $workdir/emulab-image $workdir/xvda1\n";
    $error = 1;
    goto cleanup;
}


# Tar everything up and then imagezip
my $cmd = "$TAR zcf - -C $workdir xvda1 xm.conf kernel initrd | $zipper -f - $outfile";
if (system("$cmd")) {
    print STDERR "*** Failed to create image!\n";
    print STDERR "    command: '$cmd'\n";
    $error = 1;
    goto cleanup;
}

cleanup:
# Clean up the directory.
print STDOUT "Performing cleanup...\n";
system("$sudo /bin/rm -rf $workdir 2>/dev/null");
system("echo 'rm -Rf ~/.emulab' | ssh -o UserKnownHostsFile=/dev/null ".
            "-o StrictHostKeyChecking=no $remote bash");

exit($error);
