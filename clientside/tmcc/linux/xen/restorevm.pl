#!/usr/bin/perl -w
#
# EMULAB-COPYRIGHT
# Copyright (c) 2009-2012 University of Utah and the Flux Group.
# All rights reserved.
#
use strict;
use Getopt::Std;
use English;
use Errno;
use Data::Dumper;

sub usage()
{
    print "Usage: restorevm.pl [-d] vnodeid path\n" . 
	  "  -d   Debug mode.\n".
	  "  -i   Info mode only\n";
    exit(-1);
}
my $optlist     = "di";
my $debug       = 1;
my $infomode    = 0;
my $VMPATH      = "/var/xen/configs";
my $VGNAME	= "xen-vg";
my $IMAGEUNZIP  = "imageunzip";
my $IMAGEDUMP   = "imagedump";

#
# Turn off line buffering on output
#
$| = 1;

# Locals
my %xminfo = ();

# Protos
sub Fatal($);

#
# Parse command arguments. Once we return from getopts, all that should be
# left are the required arguments.
#
my %options = ();
if (! getopts($optlist, \%options)) {
    usage();
}
if (defined($options{"d"})) {
    $debug = 1;
}
if (defined($options{"i"})) {
    $infomode = 1;
}
usage()
    if (@ARGV != 2);

my $vnodeid = $ARGV[0];
my $path    = $ARGV[1];
my $XMINFO  = "$path/xm.conf";

# Must supply an absolute path.
if (! ($path =~ /^\//)) {
    Fatal("Must supply an absolute path");
}

if (! -e $IMAGEUNZIP) {
    $IMAGEUNZIP  = "/usr/local/bin/imageunzip";
    $IMAGEDUMP   = "/usr/local/bin/imagedump";
}

#
# We need this file to figure out the disk info.
#
if (! -e "$XMINFO") {
    Fatal("$XMINFO does not exist");
}
open(XM, $XMINFO)
    or Fatal("Could not open $XMINFO: $!");
while (<XM>) {
    if ($_ =~ /^([-\w]*)\s*=\s*(.*)$/) {
	my $key = $1;
	my $val = $2;
	if ($val =~ /^'(.*)'$/) {
	    $val = $1;
	}
	$xminfo{$key} = "$val";
    }
    elsif ($_ =~ /^([-\w]*)\s*[\+\=]+\s*(.*)$/) {
	my $key = $1;
	my $val = $2;
	if ($val =~ /^'(.*)'$/) {
	    $val = $1;
	}
	$xminfo{$key} .= $val;
    }
}
close(XM);

#
# Localize the path to the kernel.
#
$xminfo{"kernel"} = $path . "/" . $xminfo{"kernel"};

#
# Fix up the network interfaces.
#
my $ifacelist = eval $xminfo{'vif'};
my @newifaces = ();
foreach my $vif (@$ifacelist) {
    my ($mac, $bridge) = split(',', $vif);
    my (undef, $iface) = split('=', $bridge);

    $iface =~ s/eth/xenbr/;
    push(@newifaces, "$mac, bridge=$iface");
}
# XXX Ick!
if ($vnodeid eq "boss") {
    for (my $i = 1; $i < 4; $i++) {
	my $iface = "xenbr$i";
	my $mac   = "00:00:99:98:97:0$i";
	push(@newifaces, "mac=$mac, bridge=$iface");
    }
}
$xminfo{'vif'} = "[" . join(",", map {"'$_'" } @newifaces) . "]";

#
# Parse the disk info.
#
if (!exists($xminfo{'disk'})) {
    Fatal("No disk info in config file!");
}
my $disklist = eval $xminfo{'disk'};
my %diskinfo = ();
my %disksize = ();
foreach my $disk (@$disklist) {
    if ($disk =~ /^phy:([^,]*)/) {
	$diskinfo{$1} = $disk;
    }
    else {
	Fatal("Cannot parse disk: $disk");
    }
}

#
# And the size info.
#
foreach my $spec (split(',', $xminfo{'disksizes'})) {
    my ($dev,$size) = split(':', $spec);

    $disksize{$dev} = $size;
}
print Dumper(\%disksize);

foreach my $physinfo (keys(%diskinfo)) {
    my $spec = $diskinfo{$physinfo};
    my $dev;
    my $filename;
    if ($spec =~ /,(sd\w+),/) {
	$dev = $1;
    }
    else {
	Fatal("Could not parse $spec");
    }
    #
    # Figure out the size of the LVM.
    #
    my $lvmsize = $disksize{$dev};
    Fatal("Could not get lvsize for $dev")
	if (!defined($lvmsize));

    #
    # Form a new lvmname and create the LVM using the size.
    #
    my $lvmname = "${vnodeid}.${dev}";
    my $device  = "/dev/$VGNAME/$lvmname";

    if (! -e $device) {
	if (!$infomode) {
	    system("lvcreate -n $lvmname -L $lvmsize $VGNAME") == 0
		or Fatal("Could not create lvm for $lvmname");
	}
    }
    # Rewrite the diskinfo path for new xm.conf
    delete($diskinfo{$physinfo});
    $diskinfo{$device} = "phy:$device,$dev,w";

    #
    # For swap, just need to mark it as a linux swap partition.
    #
    if ($spec =~ /swap/) {
	#
	# Mark it as a linux swap partition. 
	#
	if (!$infomode &&
	    system("echo ',,S' | sfdisk $device -N0")) {
	    Fatal("Could not mark $device as linux swap");
	}
	next;
    }
    $filename = "$path/$dev";
    Fatal("$filename does not exist")
	if (! -e $filename);

    print "Working on $filename.\n";
    print "Size is $lvmsize. Writing to $device\n";
    
    #
    # The root FS is a single partition image, while the aux disks
    # have a real MBR in them. 
    #
    my $opts = "-W 256";
    if ($infomode) {
	system("$IMAGEDUMP $filename");
    }
    else {
	system("$IMAGEUNZIP -o $opts $filename $device");
    }
}

#
# Write out the config file.
#
delete($xminfo{"disksizes"});
$xminfo{"name"}   = $vnodeid;
$xminfo{"memory"} = "2048";
$xminfo{"disk"}   = "[" . join(",", map {"'$_'" } values(%diskinfo)) . "]";

if ($infomode) {
    print Dumper(\%xminfo);
}
else {
    #
    # Before we write it out, need to munge the vif spec since there is
    # no need for the script. Use just the default.
    #
    $XMINFO = "/var/tmp/${vnodeid}.conf";
    print "Writing new xen config to $XMINFO\n";
    
    open(XM, ">$XMINFO")
	or fatal("Could not open $XMINFO: $!");
    foreach my $key (keys(%xminfo)) {
	my $val = $xminfo{$key};
	if ($val =~ /^\[/) {
	    print XM "$key = $val\n";
	}
	else {
	    print XM "$key = '$val'\n";
	}
    }
    close(XM);
}

exit(0);

sub Fatal($)
{
    my ($msg) = @_;

    die("*** $0:\n".
	"    $msg\n");
}

