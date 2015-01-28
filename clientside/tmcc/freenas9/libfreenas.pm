#!/usr/bin/perl -wT
#
# Copyright (c) 2013-2015 University of Utah and the Flux Group.
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
# Support functions for the libvnode API and also for bscontrol which is
# a proxy for the blockstore server control program on boss.
#

package libfreenas;
use Exporter;
@ISA    = "Exporter";
@EXPORT =
    qw( 
	freenasPoolList freenasVolumeList
	freenasVolumeCreate freenasVolumeDestroy freenasFSCreate
	freenasVolumeSnapshot freenasVolumeClone
	freenasVolumeDesnapshot freenasVolumeDeclone
	freenasRunCmd freenasParseListing
	$FREENAS_CLI_VERB_IFACE $FREENAS_CLI_VERB_IST_EXTENT
	$FREENAS_CLI_VERB_IST_AUTHI $FREENAS_CLI_VERB_IST_TARGET
	$FREENAS_CLI_VERB_IST_ASSOC $FREENAS_CLI_VERB_VLAN
	$FREENAS_CLI_VERB_VOLUME $FREENAS_CLI_VERB_POOL
	$FREENAS_CLI_VERB_SNAPSHOT
    );

use strict;
use English;
use Data::Dumper;
use Socket;
use File::Basename;
use File::Path;
use File::Copy;

# Pull in libvnode and other Emulab stuff
BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }
use libutil;
use libtestbed;
use libsetup;


#
# Exported CLI constants
#
our $FREENAS_CLI_VERB_IFACE       = "interface";
our $FREENAS_CLI_VERB_IST_EXTENT  = "ist_extent";
our $FREENAS_CLI_VERB_IST_AUTHI   = "ist_authinit";
our $FREENAS_CLI_VERB_IST_TARGET  = "ist";
our $FREENAS_CLI_VERB_IST_ASSOC   = "ist_assoc";
our $FREENAS_CLI_VERB_VLAN        = "vlan";
our $FREENAS_CLI_VERB_VOLUME      = "volume";
our $FREENAS_CLI_VERB_POOL        = "pool";
our $FREENAS_CLI_VERB_SNAPSHOT    = "snapshot";

#
# Constants
#
my $GLOBAL_CONF_LOCK     = "blkconf";
my $ZPOOL_CMD            = "/sbin/zpool";
my $ZFS_CMD              = "/sbin/zfs";
my $ZPOOL_STATUS_UNKNOWN = "unknown";
my $ZPOOL_STATUS_ONLINE  = "online";
my $ZPOOL_LOW_WATERMARK  = 2 * 2**10; # 2GiB, expressed in MiB
my $FREENAS_MNT_PREFIX   = "/mnt";
my $ISCSI_GLOBAL_PORTAL  = 1;
my $SER_PREFIX           = "d0d0";
my $VLAN_IFACE_PREFIX    = "vlan";
my $MAX_RETRY_COUNT      = 5;
my $VOLUME_BUSY_WAIT      = 10;
my $VOLUME_GONE_WAIT      = 5;
my $IFCONFIG             = "/sbin/ifconfig";
my $ALIASMASK            = "255.255.255.255";
my $LINUX_MKFS		 = "/usr/local/sbin/mke2fs";
my $FBSD_MKFS		 = "/sbin/newfs";

# storageconfig constants
# XXX: should go somewhere more general
my $BS_CLASS_SAN         = "SAN";
my $BS_PROTO_ISCSI       = "iSCSI";
my $BS_UUID_TYPE_IQN     = "iqn";

# CLI stuff
my $FREENAS_CLI          = "$BINDIR/freenas-config";

my %cliverbs = (
    $FREENAS_CLI_VERB_IFACE      => 1,
    $FREENAS_CLI_VERB_IST_EXTENT => 1,
    $FREENAS_CLI_VERB_IST_AUTHI  => 1,
    $FREENAS_CLI_VERB_IST_TARGET => 1,
    $FREENAS_CLI_VERB_IST_ASSOC  => 1,
    $FREENAS_CLI_VERB_VLAN       => 1,
    $FREENAS_CLI_VERB_VOLUME     => 1,
    $FREENAS_CLI_VERB_POOL       => 1,
    $FREENAS_CLI_VERB_SNAPSHOT   => 1,
    );

#
# Global variables
#
my $debug  = 0;

sub freenasPoolList();
sub freenasVolumeList($;$);
sub freenasVolumeCreate($$$);
sub freenasVolumeDestroy($$);
sub freenasFSCreate($$$);
sub freenasRunCmd($$);
sub freenasParseListing($);

sub freenasVolumeSnapshot($$;$);
sub freenasVolumeDesnapshot($$;$);
sub freenasVolumeClone($$$;$);
sub freenasVolumeDeclone($$);

#
# Local Functions
#
sub listPools();
sub convertZfsToMebi($);
sub volumeDestroy($$$$);

#
# Turn off line buffering on output
#
$| = 1;

sub setDebug($)
{
    $debug = shift;
    print "libfreenas: debug=$debug\n"
	if ($debug);
}

sub freenasVolumeList($;$)
{
    my ($inameinfo,$snapinfo) = @_;
    my $vollist = {};

    $inameinfo = 0 if (!defined($inameinfo));
    $snapinfo  = 0 if (!defined($snapinfo));

    #
    # Extract blockstores from the freenas volume info and augment
    # with slice info where it exists.
    # 
    my %inames = ();
    if ($inameinfo) {
	my @slist = freenasParseListing($FREENAS_CLI_VERB_IST_EXTENT);
	foreach my $slice (@slist) {
	    if ($slice->{'path'} =~ /^zvol\/([-\w]+\/[-\w+]+)$/) {
		$inames{$1} = $slice->{'name'};
	    }
	}
    }

    # volume-name -> (snapshot1 snapshot2 ...)
    my %snaps = ();
    # clone-volume-name -> snapshot
    my %clones = ();
    if ($snapinfo) {
	my @slist = freenasParseListing($FREENAS_CLI_VERB_SNAPSHOT);
	my @snames = ();
	foreach my $snap (@slist) {
	    my $vol = $snap->{'vol_name'};
	    next if (!$vol);

	    # XXX only handle zvols right now
	    next if ($snap->{'snap_parent'} ne 'volume');

	    if ($snap->{'snap_name'} =~ /^(.*)\/([^\/]+)$/) {
		my $sname = $2;
		push(@snames, "$1/$2");
		$snaps{$vol} = [ ] if (!exists($snaps{$vol}));
		push(@{$snaps{$vol}}, $sname);
	    }
	}

	# have to use "zfs get" to get clone info
	if (open(ZFS, "$ZFS_CMD get -o name,value -Hp clones @snames |")) {
	    while (my $line = <ZFS>) {
		chomp $line;
		my ($name, $val) = split(/\s+/, $line);
		if ($name =~ /\/([^\/]+)$/) {
		    my $sname = $1;
		    foreach my $clone (split(',', $val)) {
			$clones{$clone} = $sname;
		    }
		}
	    }
	    close(ZFS);
	} else {
	    warn("*** WARNING: could not run 'zfs get' for clone info");
	}
    }

    my @zvols = freenasParseListing($FREENAS_CLI_VERB_VOLUME);
    foreach my $zvol (@zvols) {
	my $vol = {};
	if ($zvol->{'vol_name'} =~ /^([-\w]+)\/([-\w+]+)$/) {
	    $vol->{'pool'} = $1;
	    $vol->{'volume'} = $2;
	    $vol->{'size'} = convertZfsToMebi($zvol->{'vol_size'});
	    if ($inameinfo && exists($inames{$zvol->{'vol_name'}})) {
		$vol->{'iname'} = $inames{$zvol->{'vol_name'}};
	    }
	    if ($snapinfo) {
		my $sref = $snaps{$zvol->{'vol_name'}};
		if ($sref && @$sref > 0) {
		    $vol->{'snapshots'} = join(',', @$sref);
		}
		my $sname = $clones{$zvol->{'vol_name'}};
		if ($sname) {
		    $vol->{'cloneof'} = $sname;
		}
	    }
	    $vollist->{$vol->{'volume'}} = $vol;
	}
    }

    return $vollist;
}

sub freenasPoolList() {
    return listPools();
}

sub freenasVolumeCreate($$$)
{
    my ($pool, $volname, $size) = @_;

    # Untaint arguments since they are passed to a command execution
    $pool = untaintHostname($pool);
    $volname = untaintHostname($volname);
    $size = untaintNumber($size);
    if (!$pool || !$volname || !$size) {
	warn("*** ERROR: freenasVolumeCreate: ".
	     "Invalid arguments");
	return -1;
    }

    # Does the requested pool exist?
    my $pools = listPools();
    my $destpool;
    if (exists($pools->{$pool})) {
	$destpool = $pools->{$pool};
    } else {
	warn("*** ERROR: freenasVolumeCreate: ".
	     "Requested pool not found: $pool!");
	return -1;
    }

    # Is there enough space in the requested pool?
    # If not, there is a discrepancy between reality and the Emulab database.
    if ($size + $ZPOOL_LOW_WATERMARK > $destpool->{'avail'}) {
	warn("*** ERROR: freenasVolumeCreate: ". 
	     "Not enough space remaining in requested pool: $pool");
	return -1;
    }

    # Allocate volume in zpool
    eval { freenasRunCmd($FREENAS_CLI_VERB_VOLUME, 
			 "add $pool $volname ${size}MB off") };
    if ($@) {
	my $msg = "  $@";
	$msg =~ s/\\n/\n  /g;
	warn("*** ERROR: freenasVolumeCreate: ".
	     "volume allocation failed:\n$msg");
	return -1;
    }

    return 0;
}

sub freenasVolumeSnapshot($$;$)
{
    my ($pool, $volname, $tstamp) = @_;

    # Untaint arguments that are passed to a command execution
    $pool = untaintHostname($pool);
    $volname = untaintHostname($volname);
    if (defined($tstamp) && $tstamp != 0) {
	$tstamp = untaintNumber($tstamp);
    } else {
	$tstamp = time();
    }
    if (!$pool || !$volname || !$tstamp) {
	warn("*** ERROR: freenasVolumeSnapshot: ".
	     "Invalid arguments");
	return -1;
    }

    # Get volume and snapshot info
    my $vollist = freenasVolumeList(0, 1);

    # The base volume must exist
    my $vref = $vollist->{$volname};
    if (!$vref || $vref->{'pool'} ne $pool) {
	warn("*** ERROR: freenasVolumeSnapshot: ".
	     "Base volume '$volname' does not exist in pool '$pool'");
	return -1;
    }

    # The snapshot must not exist
    my $snapshot = "$volname\@$tstamp";
    if (exists($vref->{'snapshots'})) {
	my @snaps = split(',', $vref->{'snapshots'});

	foreach my $sname (@snaps) {
	    if ($snapshot eq $sname) {
		warn("*** ERROR: freenasVolumeSnapshot: ".
		     "Snapshot '$snapshot' already exists");
		return -1;
	    }
	}
    }

    # Let's do it!
    eval { freenasRunCmd($FREENAS_CLI_VERB_SNAPSHOT,
			 "add $pool/$snapshot") };
    if ($@) {
	my $msg = "  $@";
	$msg =~ s/\\n/\n  /g;
	warn("*** ERROR: freenasVolumeSnapshot: ".
	     "'add $pool/$snapshot' failed:\n$msg");
	return -1;
    }

    return 0;
}

sub freenasVolumeDesnapshot($$;$)
{
    my ($pool, $volname, $tstamp) = @_;

    # Untaint arguments that are passed to a command execution
    $pool = untaintHostname($pool);
    $volname = untaintHostname($volname);
    if (defined($tstamp)) {
	$tstamp = untaintNumber($tstamp);
    } else {
	$tstamp = 0;
    }
    if (!$pool || !$volname || !defined($tstamp)) {
	warn("*** ERROR: freenasVolumeSnapshot: ".
	     "Invalid arguments");
	return -1;
    }

    # Get volume and snapshot info
    my $vollist = freenasVolumeList(0, 1);

    # The base volume must exist
    my $vref = $vollist->{$volname};
    if (!$vref || $vref->{'pool'} ne $pool) {
	warn("*** ERROR: freenasVolumeDesnapshot: ".
	     "Base volume '$volname' does not exist in pool '$pool'");
	return -1;
    }

    # Loop through removing snapshots as appropriate.
    my $rv = 0;
    if (exists($vref->{'snapshots'})) {
	my @snaps = split(',', $vref->{'snapshots'});
	my $snapshot = "$volname\@$tstamp"
	    if ($tstamp);

	foreach my $sname (@snaps) {
	    if (!$tstamp || $snapshot eq $sname) {
		eval { freenasRunCmd($FREENAS_CLI_VERB_SNAPSHOT, 
				     "del $pool/$sname") };
		if ($@) {
		    if ($@ =~ /has dependent clones/) {
			warn("*** WARNING: freenasVolumeDesnapshot: ".
			     "snapshot '$sname' in use");

			#
			# XXX only return an error for this case if we are
			# removing a specific snapshot. Otherwise, it causes
			# too much drama up the line for something that is
			# "normal" (i.e., we are attempting to remove all
			# snapshots and some of them are in use).
			#
			if ($tstamp) {
			    $rv = -1;
			}
		    } else {
			my $msg = "  $@";
			$msg =~ s/\\n/\n  /g;
			warn("*** ERROR: freenasVolumeDesnapshot: ".
			     "'del $pool/$snapshot' failed:\n$msg");

			# if it isn't an "in use" error, we really do fail
			$rv = -1;
		    }
		}
	    }
	}
    }

    return $rv;
}

#
# Create a clone volume named $nvolname from volume $ovolname.
# The clone will be created from the snapshot $volname-$tag where
# $tag is interpreted as a timestamp. If $tag == 0, use the most recent
# (i.e., largest timestamp) snapshot.
#
sub freenasVolumeClone($$$;$)
{
    my ($pool, $ovolname, $nvolname, $tag) = @_;

    # Untaint arguments that are passed to a command execution
    $pool = untaintHostname($pool);
    $ovolname = untaintHostname($ovolname);
    $nvolname = untaintHostname($nvolname);
    if (defined($tag)) {
	$tag = untaintNumber($tag);
    } else {
	$tag = 0;
    }
    if (!$pool || !$ovolname || !$nvolname || !defined($tag)) {
	warn("*** ERROR: freenasVolumeClone: ".
	     "Invalid arguments");
	return -1;
    }

    # Get volume and snapshot info
    my $vollist = freenasVolumeList(0, 1);

    # The base volume must exist, the clone must not
    my $ovref = $vollist->{$ovolname};
    if (!$ovref || $ovref->{'pool'} ne $pool) {
	warn("*** ERROR: freenasVolumeClone: ".
	     "Base volume '$ovolname' does not exist in pool '$pool'");
	return -1;
    }
    if (exists($vollist->{$nvolname})) {
	warn("*** ERROR: freenasVolumeClone: ".
	     "Volume '$nvolname' already exists");
	return -1;
    }

    # Base must have at least one snapshot
    if (!exists($ovref->{'snapshots'})) {
	warn("*** ERROR: freenasVolumeClone: ".
	     "Base volume '$ovolname' has no snapshots");
	return -1;
    }
    my @snaps = split(',', $ovref->{'snapshots'});

    # If specified explicitly, the named snapshot must exist
    my $snapshot;
    if ($tag) {
	my $found = 0;
	$snapshot = "$ovolname\@$tag";
	foreach my $sname (@snaps) {
	    if ($snapshot eq $sname) {
		$found = 1;
		last;
	    }
	}
	if (!$found) {
	    warn("*** ERROR: freenasVolumeClone: ".
		 "Snapshot '$snapshot' does not exist");
	    return -1;
	}
    }

    # Otherwise find the most recent snapshot
    else {
	foreach my $sname (@snaps) {
	    if ($sname =~ /^$ovolname\@(\d+)$/ && $1 > $tag) {
		$tag = $1;
	    }
	}
	$snapshot = "$ovolname\@$tag";
    }

    # Let's do it!
    eval { freenasRunCmd($FREENAS_CLI_VERB_SNAPSHOT,
			 "clone $pool/$snapshot $pool/$nvolname") };
    if ($@) {
	my $msg = "  $@";
	$msg =~ s/\\n/\n  /g;
	warn("*** ERROR: freenasVolumeClone: ".
	     "'clone $pool/$snapshot $pool/$nvolname' failed:\n$msg");
	return -1;
    }

    return 0;
}

sub freenasVolumeDeclone($$)
{
    my ($pool, $volname) = @_;

    # Untaint arguments since they are passed to a command execution
    $pool = untaintHostname($pool);
    $volname = untaintHostname($volname);
    if (!$pool || !$volname) {
	warn("*** ERROR: freenasVolumeDeclone: ".
	     "Invalid arguments");
	return -1;
    }

    return volumeDestroy($pool, $volname, 1, "freenasVolumeDeclone");
}

sub freenasVolumeDestroy($$)
{
    my ($pool, $volname) = @_;

    # Untaint arguments since they are passed to a command execution
    $pool = untaintHostname($pool);
    $volname = untaintHostname($volname);
    if (!$pool || !$volname) {
	warn("*** ERROR: freenasVolumeDestroy: ".
	     "Invalid arguments");
	return -1;
    }

    return volumeDestroy($pool, $volname, 0, "freenasVolumeDestroy");
}

#
# The guts of destroy and declone
#
sub volumeDestroy($$$$) {
    my ($pool, $volname, $declone, $tag) = @_;

    # Get volume and snapshot info
    my $vollist = freenasVolumeList(0, 1);

    # Volume must exist
    my $vref = $vollist->{$volname};
    if (!$vref || $vref->{'pool'} ne $pool) {
	warn("*** ERROR: $tag: ".
	     "Volume '$volname' does not exist in pool '$pool'");
	return -1;
    }

    # Volume must not have snapshots
    if (exists($vref->{'snapshots'})) {
	warn("*** ERROR: $tag: ".
	     "Volume '$volname' has clones, cannot destroy");
	return -1;
    }
 
    # Deallocate volume.  Wrap in loop to enable retries.
    my $count;
    for ($count = 1; $count <= $MAX_RETRY_COUNT; $count++) {
	eval { freenasRunCmd($FREENAS_CLI_VERB_VOLUME, 
			     "del $pool $volname") };
	# Process exceptions thrown during deletion attempt.  Retry on
	# some errors.
	if ($@) { 
	    if ($@ =~ /dataset is busy/) {
		warn("*** WARNING: $tag: ".
		     "Volume is busy. ".
		     "Waiting $VOLUME_BUSY_WAIT seconds before trying again ".
		     "(count=$count).");
		sleep $VOLUME_BUSY_WAIT;
	    }
	    elsif ($@ =~ /does not exist/) {
		if ($count < $MAX_RETRY_COUNT) {
		    warn("*** WARNING: $tag: ".
			 "Volume seems to be gone, retrying.");
		    # Bump counter to just under termination to try once more.
		    $count = $MAX_RETRY_COUNT-1;
		    sleep $VOLUME_GONE_WAIT;
		} else {
		    warn("*** WARNING: $tag: ".
			 "Volume still seems to be gone.");
		    # Bail now because we don't want to report this as an
		    # error to the caller.
		    return 0;
		}
	    } 
	    else {
		my $msg = "  $@";
		$msg =~ s/\\n/\n  /g;
		warn("*** ERROR: $tag: ".
		     "Volume removal failed:\n$msg");
		return -1;
	    }
	} else {
	    # No error condition - jump out of loop.
	    last;
	}
    }

    # Note: Checks for lingering volumes will be performed separately in
    # consistency checking routines.

    if ($count > $MAX_RETRY_COUNT) {
	warn("*** WARNING: $tag: ".
	     "Could not free volume after several attempts!");
	return -1;
    }

    #
    # If decloning, see if we can whack the snapshot
    #
    if (exists($vref->{'cloneof'})) {
	my $snapshot = $vref->{'cloneof'};
	if ($declone) {
	    eval { freenasRunCmd($FREENAS_CLI_VERB_SNAPSHOT, 
				 "del $pool/$snapshot") };
	    if ($@) {
		if ($@ =~ /has dependent clones/) {
		    return 0;
		}
		my $msg = "  $@";
		$msg =~ s/\\n/\n  /g;
		warn("*** ERROR: freenasVolumeDeclone: ".
		     "'del $pool/$snapshot' failed:\n$msg");
		return -1;
	    }
	} else {
	    warn("*** WARNING: $tag: ".
		 "Destroying clone but not origin snapshot '$snapshot'");
	}
    }

    return 0;
}

#
# Run a FreeNAS CLI command, checking for a return error and other
# such things.  We check that the incoming verb is valid.  Command line
# argument string needs to be untainted or this will fail.
#
# Throws exceptions (dies), passing along errors in $@.
#
sub freenasRunCmd($$) {
    my ($verb, $argstr) = @_;

    my $errstate = 0;
    my $message;

    die "Invalid FreeNAS CLI verb: $verb"
	unless exists($cliverbs{$verb});

    print "DEBUG: blockstore_freenasRunCmd:\n".
	"\trunning: $verb $argstr\n" if $debug;

    my $output = `$FREENAS_CLI $verb $argstr 2>&1`;

    if ($? != 0) {
	$errstate = 1;
	$output =~ /^(.+Error: .+)$/;
	$message = defined($1) ? $1 : "Error code: $?";
    } elsif ($output =~ /"error": true/) {
	$errstate = 1;
	$output =~ /"message": "([^"]+)"/;
	$message = defined($1) ? $1 : "Unknown error";
    }

    if ($errstate) {
	print STDERR $output if $debug;
	die $message;
    }

    return 0;
}

# Run our custom FreeNAS CLI to extract info.  
#
# Returns an array of hash references.  Each hash contains info from
# one line of output.  The hash keys are the field names from the
# header (first line of output).  The hash values are the
# corresponding pieces of data at each field location in a line.
sub freenasParseListing($) {
    my $verb = shift;
    my @retlist = ();

    die "Invalid FreeNAS CLI verb: $verb"
	unless exists($cliverbs{$verb});

    open(CLI, "$FREENAS_CLI $verb list |") or
	die "Can't run FreeNAS CLI: $!";

    my $header = <CLI>;

    return @retlist
	if !defined($header) or !$header;

    chomp $header;
    my @fields = split(/\t/, $header);

    while (my $line = <CLI>) {
	chomp $line;
	my @lparts = split(/\t/, $line);
	if (scalar(@lparts) != scalar(@fields)) {
	    warn("*** WARNING: blockstore_freenasParseListing: ".
		 "Bad output from CLI ($verb): $line");
	    next;
	}
	my %lineh = ();
	for (my $i = 0; $i < scalar(@fields); $i++) {
	    $lineh{$fields[$i]} = $lparts[$i];
	}
	push @retlist, \%lineh;
    }
    close(CLI);
    return @retlist;
}

sub freenasFSCreate($$$) {
    my ($pool,$vol,$fstype) = @_;
    my $cmd;

    if ($fstype =~ /^ext[234]$/) {
	$cmd = "$LINUX_MKFS -t $fstype -o Linux";
    } elsif ($fstype eq "ufs") {
	$cmd = "$FBSD_MKFS";
    } else {
	warn("*** WARNING: freenasFSCreate: unknown fs type '$fstype'");
	return -1;
    }
    my $redir = ">/dev/null 2>&1";
    if (system("$cmd /dev/zvol/$pool/$vol $redir") != 0) {
	warn("*** WARNING: freenasFSCreate: '$cmd /dev/zvol/$pool/$vol' failed");
	return -1;
    }

    return 0;
}

#######################################################################
# package-local functions
#

#
# Return information on all of the volume pools available on this host.
# Note: to get exact sizes, we execute our own zfs command, e.g:
#
#   zfs get -o name,property,value -Hp available,used rz-1
#
# where "rz-1" is the "root" of the pool. We need -p so that zfs doesn't
# return "human readable" sizes. Zfs rounds up those sizes to the appropriate
# number of significant digits. However, rounding up available space makes
# it seem like we have more space than we actually do! E.g., 39.35T to 39.4T
# will be off by 50GB.
#
sub listPools() {
    my $poolh = {};
    my @pools = freenasParseListing($FREENAS_CLI_VERB_POOL);
    
    # Create hash with pool name as key.  Stuff in some sentinel values
    # in case we don't get a match from 'zpool list' below.
    foreach my $pool (@pools) {
	$pool->{'size'} = 0;
	$pool->{'avail'} = 0;
	$poolh->{$pool->{'volume_name'}} = $pool;
    }

    # Yuck - have to go after capacity and status info by calling the
    # 'zfs' command line utility since the CLI doesn't return this info.
    open(ZFS, "$ZFS_CMD get -o name,property,value -Hp used,avail |") or
	die "Can't run 'zfs get'!";

    while (my $line = <ZFS>) {
	chomp $line;
	my ($pname, $prop, $val) = split(/\s+/, $line);
	next if $pname =~ /\//;  # filter out zvols.
	if (exists($poolh->{$pname})) {
	    my $pool = $poolh->{$pname};
	    if ($prop eq "available") {
		$pool->{'avail'} = convertZfsToMebi($val);
	    } elsif ($prop eq "used") {
		$pool->{'used'} = convertZfsToMebi($val);
	    }
	} else {
	    warn("*** WARNING: blockstore_getPoolInfo: ".
		 "No FreeNAS entry for zpool: $pname");
	}
    }
    close(ZFS);

    # calculates sizes for each pool based on used, avail
    foreach my $pname (keys %$poolh) {
	my $pool = $poolh->{$pname};
	if (!exists($pool->{'used'}) ||
	    !exists($pool->{'avail'})) {
	    warn("*** WARNING: blockstore_getPoolInfo: ".
		 "incomplete size info for zpool: $pname");
	} else {
	    $pool->{'size'} = $pool->{'used'} + $pool->{'avail'};
	}
    }

    return $poolh;
}

#
# ZFS uses "KB", "MB", etc. when it really means "KiB", "MiB", etc.
#
sub convertZfsToMebi($) {
    my ($zsize) = @_;

    if ($zsize =~ /([\d\.]+[KMGT])B?$/) {
	$zsize = $1 . "iB";
    }
    return convertToMebi($zsize);
}

# Required perl foo
1;
