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
    print "Usage: capturevm.pl [-d] vnodeid [role]\n" . 
	  "  -d   Debug mode.\n".
	  "  -i   Info mode only\n";
    exit(-1);
}
my $optlist     = "di";
my $debug       = 1;
my $infomode    = 0;
my $VMPATH      = "/var/emulab/vms/vminfo";
my $EXTRAFS	= "/extrafs";
my $VGNAME	= "xen-vg";
my $role;

#
# Turn off line buffering on output
#
$| = 1;

# Locals
my %xminfo = ();

# Protos
sub Fatal($);
sub CreateExtraFS();

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
    if (@ARGV < 1 || @ARGV > 2);

my $vnodeid = $ARGV[0];
$role       = $ARGV[1] if (@ARGV == 2);
my $XMINFO  = "$VMPATH/$vnodeid/xm.conf";

CreateExtraFS();
system("mkdir $EXTRAFS/$role")
    if (defined($role) && ! -e "$EXTRAFS/$role");

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
# Filled in later.
$xminfo{"disksizes"} = "";

#
# Parse the disk info.
#
if (!exists($xminfo{'disk'})) {
    Fatal("No disk info in config file!");
}
my $disklist = eval $xminfo{'disk'};
my %diskinfo = ();
foreach my $disk (@$disklist) {
    if ($disk =~ /^phy:([^,]*)/) {
	if (! -e $1) {
	    Fatal("$disk does not exist")
	}
	$diskinfo{$1} = {"spec" => $disk};
    }
    else {
	Fatal("Cannot parse disk: $disk");
    }
}

foreach my $device (keys(%diskinfo)) {
    my $spec = $diskinfo{$device}->{"spec"};
    my $dev;
    my $filename;
    if ($spec =~ /,(sd\w+),/) {
	$dev = $1;
    }
    else {
	fatal("Could not parse $spec");
    }
    $filename = $dev;
    $filename = "$role/$filename"
	if (defined($role));

    #
    # Figure out the size of the LVM.
    #
    my $lv_size = `lvs -o lv_size --noheadings --units g $device`;
    fatal("Could not get lvsize for $device")
	if ($?);
    chomp($lv_size);
    $lv_size =~ s/^\s+//;
    $lv_size =~ s/\s+$//;

    #
    # We store the size in the xminfo so we can write out a new one.
    # The sizes are for building the lvms later.
    #
    $xminfo{"disksizes"} .= ","
	if ($xminfo{"disksizes"} ne "");
    $xminfo{"disksizes"} .= "$dev:$lv_size";
    
    #
    # Do not need to do anything. 
    #
    if ($device =~ /swap/) {
	next;
    }
    print "Working on $device.\n";
    print "Size is $lv_size. Writing to $EXTRAFS/$filename\n";
    
    #
    # The root FS is a single partition image, while the aux disks
    # have a real MBR in them. 
    #
    my $opts = "";
    if (! ($device =~ /disk/)) {
	$opts = "-b -f";
    }
    if ($infomode) {
	system("imagezip -i $opts $device");
    }
    else {
	system("imagezip -o $opts $device $EXTRAFS/$filename");
    }
}

#
# Write out the config file.
#
if ($infomode) {
    print Dumper(\%xminfo);
}
else {
    #
    # Before we write it out, need to munge the vif spec since there is
    # no need for the script. Use just the default.
    #
    $xminfo{"vif"} =~ s/,\s*script=[^\']*//g;

    $XMINFO = (defined($role) ? "$EXTRAFS/$role/xm.conf" : "$EXTRAFS/xm.conf");
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

#
# Create an extra FS using an LVM.
#
sub CreateExtraFS()
{
    return
	if (-e $EXTRAFS);

    system("mkdir $EXTRAFS") == 0
	or fatal("mkdir($EXTRAFS) failed");
    
    system("/usr/sbin/lvcreate -n extrafs -L 50G $VGNAME") == 0
	or fatal("lvcreate failed");

    system("mke2fs -j /dev/$VGNAME/extrafs") == 0
	or fatal("mke2fs failed");

    system("mount /dev/$VGNAME/extrafs $EXTRAFS") == 0
	or fatal("mount failed");
}

sub Fatal($)
{
    my ($msg) = @_;

    die("*** $0:\n".
	"    $msg\n");
}

