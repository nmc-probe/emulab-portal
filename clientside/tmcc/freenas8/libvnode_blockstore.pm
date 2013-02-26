#!/usr/bin/perl -wT
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
# Implements the libvnode API for blockstore pseudo-VMs on FreeNAS 8
#
# Note that there is no distinguished first or last call of this library
# in the current implementation.  Every vnode creation (through mkvnode.pl)
# will invoke all the root* and vnode* functions.  It is up to us to make
# sure that "one time" operations really are executed only once.
#
# Some notes about the current implementation in this module:
#
# * No module-specific persistent state
#
#  This module does not store anything persistently outside of what
#  FreeNAS itself stores.  In other words, it refreshes it's idea of
#  what pools exist, what slices are present, etc., on demand via the
#  CLI each time it requires this information.  Slower, but more simple
#  and accurate.
#
# * Minimal parallelization
#
#  Some read-only calls don't try to grab a global lock, but everything else
#  does.  Concurrent setup requests should be pretty rare anyway.  The idea
#  here is twofold: 1) avoid hammering on the FreeNAS interface and 2)
#  ensure data about existing resources is consistent/accurate.
#
package libvnode_blockstore;
use Exporter;
@ISA    = "Exporter";
@EXPORT = qw( init setDebug rootPreConfig
              rootPreConfigNetwork rootPostConfig
	      vnodeCreate vnodeDestroy vnodeState
	      vnodeBoot vnodePreBoot vnodeHalt vnodeReboot
	      vnodeUnmount
	      vnodePreConfig vnodePreConfigControlNetwork
              vnodePreConfigExpNetwork vnodeConfigResources
              vnodeConfigDevices vnodePostConfig vnodeExec vnodeTearDown
	    );

%ops = ( 'init' => \&init,
         'setDebug' => \&setDebug,
         'rootPreConfig' => \&rootPreConfig,
         'rootPreConfigNetwork' => \&rootPreConfigNetwork,
         'rootPostConfig' => \&rootPostConfig,
         'vnodeCreate' => \&vnodeCreate,
         'vnodeDestroy' => \&vnodeDestroy,
	 'vnodeTearDown' => \&vnodeTearDown,
         'vnodeState' => \&vnodeState,
         'vnodeBoot' => \&vnodeBoot,
         'vnodeHalt' => \&vnodeHalt,
         'vnodeUnmount' => \&vnodeUnmount,
         'vnodeReboot' => \&vnodeReboot,
         'vnodeExec' => \&vnodeExec,
         'vnodePreConfig' => \&vnodePreConfig,
         'vnodePreConfigControlNetwork' => \&vnodePreConfigControlNetwork,
         'vnodePreConfigExpNetwork' => \&vnodePreConfigExpNetwork,
         'vnodeConfigResources' => \&vnodeConfigResources,
         'vnodeConfigDevices' => \&vnodeConfigDevices,
         'vnodePostConfig' => \&vnodePostConfig,
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
use libgenvnode;
use libvnode;
use libtestbed;
use libsetup;

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

# storageconfig constants
# XXX: should go somewhere more general
my $BS_CLASS_SAN         = "SAN";
my $BS_PROTO_ISCSI       = "iSCSI";
my $BS_UUID_TYPE_IQN     = "iqn";

# CLI stuff
my $FREENAS_CLI          = "$BINDIR/freenas-config";
my $CLI_VERB_IFACE       = "interface";
my $CLI_VERB_IST_EXTENT  = "ist_extent";
my $CLI_VERB_IST_AUTHI   = "ist_authinit";
my $CLI_VERB_IST_TARGET  = "ist";
my $CLI_VERB_IST_ASSOC   = "ist_assoc";
my $CLI_VERB_VLAN        = "vlan";
my $CLI_VERB_VOLUME      = "volume";
my $CLI_VERB_POOL        = "pool";

my %cliverbs = (
    $CLI_VERB_IFACE      => 1,
    $CLI_VERB_IST_EXTENT => 1,
    $CLI_VERB_IST_AUTHI  => 1,
    $CLI_VERB_IST_TARGET => 1,
    $CLI_VERB_IST_ASSOC  => 1,
    $CLI_VERB_VLAN       => 1,
    $CLI_VERB_VOLUME     => 1,
    $CLI_VERB_POOL       => 1,
    );

#
# Global variables
#
my %vnstates = ();
my $debug  = 0;

#
# Local Functions
#
sub parseFreeNASListing($);
sub getSliceList();
sub parseSliceName($);
sub parseSlicePath($);
sub calcSliceSizes($);
sub getPoolList();
sub mkVlanIfaceName($$$);
sub createVlanInterface($$);
sub runBlockstoreCmds($$);
sub removeVlanInterface($);
sub allocSlice($$$);
sub exportSlice($$$);
sub deallocSlice($$$);
sub unexportSlice($$$);

# Dispatch table for storage configuration commands.
my %setup_cmds = (
    "SLICE"  => \&allocSlice,
    "EXPORT" => \&exportSlice
);

my %teardown_cmds = (
    "SLICE"  => \&deallocSlice,
    "EXPORT" => \&unexportSlice
);

#
# Turn off line buffering on output
#
$| = 1;

sub setDebug($)
{
    $debug = shift;
    libvnode::setDebug($debug);
    print "libvnode_blockstore: debug=$debug\n"
	if ($debug);
}

#
# Called by mkvnode.pl shortly after the module is loaded.
#
sub init($) {
    # XXX: doesn't seem to be passed in presently...
    my ($pnode,) = @_;

    # Nothing to do globally (yet).
    return 0;
}

#
# Do once-per-hypervisor-boot activities.
#
# Note that this function is called for each VM, so use a marker to
# tell whether or not we've already been here, done that.  
#
# NB: Since FreeNAS uses memory filesystems for pretty much
# everything, we don't have to worry about removing the flag file on
# shutdown/reboot.
#
sub rootPreConfig() {
    #
    # Haven't been called yet, grab the lock and double check that someone
    # didn't do it while we were waiting.
    #
    if (! -e "/var/run/blockstore.ready") {
	my $locked = TBScriptLock($GLOBAL_CONF_LOCK,
				  TBSCRIPTLOCK_GLOBALWAIT(), 900);
	if ($locked != TBSCRIPTLOCK_OKAY()) {
	    return 0
		if ($locked == TBSCRIPTLOCK_IGNORE());
	    print STDERR "Could not get the blkinit lock after a long time!\n";
	    return -1;
	}
    }
    if (-e "/var/run/blockstore.ready") {
        TBScriptUnlock();
        return 0;
    }
    
    print "Configuring root vnode context\n";

    # XXX: Put in consistency checks (maybe - they may go elsewhere.)

    mysystem("touch /var/run/blockstore.ready");
    TBScriptUnlock();
    return 0;    
}

# Nothing to do ...
sub rootPreConfigNetwork($$$$)
{
    my ($vnode_id, undef, $vnconfig, $private) = @_;
    my @node_ifs = @{ $vnconfig->{'ifconfig'} };
    my @node_lds = @{ $vnconfig->{'ldconfig'} };

    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the blknet lock after a long time!\n";
	return -1;
    }

    # XXX: Nothing to do?

    TBScriptUnlock();
    return 0;
}

# Nothing to do.
sub rootPostConfig($)
{
    return 0;
}

#
# Report back the current status of the blockstore slice.
#
sub vnodeState($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    # Do we exist?
    my $slices = getSliceList();
    if (exists($slices->{$vnode_id})) {
	# We do, but have we been visited yet (i.e., are we 'booted'?)
	if (!exists($vnstates{$vnode_id})) {
	    $vnstates{$vnode_id} = VNODE_STATUS_STOPPED();
	}
	# We've been visited.  Our state should be managed elsewhere now.
    } else {
	# We don't seem to exist...
	$vnstates{$vnode_id} = VNODE_STATUS_UNKNOWN();
    }

    return $vnstates{$vnode_id};
}

# All the creation heavy lifting is coordinated from here for blockstores.
sub vnodeCreate($$$$)
{
    my ($vnode_id, undef, $vnconfig, $private) = @_;
    my $vninfo = $private;

    # Create vmid from the vnode's name.
    my $vmid;
    if ($vnode_id =~ /^\w+\d+\-(\d+)$/) {
	$vmid = $1;
    } else {
	fatal("blockstore_vnodeCreate: ".
	      "bad vnode_id $vnode_id!");
    }
    $vninfo->{'vmid'} = $vmid;
    $private->{'vndir'} = VNODE_PATH() . "/$vnode_id";

    # Grab the global lock to prevent concurrency.
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	fatal("blockstore_vnodeCreate: ".
	      "Could not get the blkalloc lock after a long time!");
    }

    # Create the experimental net (tagged vlan) interface
    if (createVlanInterface($vnode_id, $vnconfig) != 0) {
	TBScriptUnlock();
	fatal("blockstore_vnodeCreate: ".
	      "Failed to create experimental network interface!");
    }

    # Create blockstore slice
    if (runBlockstoreCmds($vnode_id, $vnconfig) != 0) {
	TBScriptUnlock();
	fatal("blockstore_vnodeCreate: ".
	      "Blockstore slice creation failed!");
    }

    TBScriptUnlock();
    return $vmid;
}

# Nothing to do presently.
sub vnodePreConfig($$$$$){
    my ($vnode_id, $vmid, $vnconfig, $private, $callback) = @_;

    return 0;
}

# Blockstore pseudo-VMs do not have a control network to setup.
sub vnodePreConfigControlNetwork($$$$$$$$$$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private,
	$ip,$mask,$mac,$gw, $vname,$longdomain,$shortdomain,$bossip) = @_;

    return 0;
}

# All setup/creation is handled elsewhere.
sub vnodePreConfigExpNetwork($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

# Nothing to do.
sub vnodeConfigResources($$$$){
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

# Nothing to do.
sub vnodeConfigDevices($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

# The blockstore slice should be setup, the vlan interface created and
# plumbed, and the export in place by now.  Just signal "ISUP".
sub vnodeBoot($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $vninfo = $private;

    # notify Emulab that we are up.  Have to go through the proper
    # state transitions...
    libutil::setState("BOOTING");
    libutil::setState("ISUP");
    $vnstates{$vnode_id} = VNODE_STATUS_RUNNING();

    return 0;
}

# Nothing to do.
sub vnodePostConfig($)
{
    return 0;
}

# blockstores don't "reboot", but we'll signal that we've gone through
# the motions anyway.  Hopefully this rapid firing of events doesn't freak
# out stated.
sub vnodeReboot($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    libutil::setState("SHUTDOWN");
    libutil::setState("BOOTING");
    libutil::setState("ISUP");
    $vnstates{$vnode_id} = VNODE_STATUS_RUNNING();

    return 0;
}

# Do everything in the "destroy" function.
sub vnodeTearDown($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

# Reverse the list of 'storageconfig' setup directives, then run the
# corresponding teardown commands.  Hold the lock while we do this
# to avoid concurrency here.
sub vnodeDestroy($$$$){
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $sconfigs = $vnconfig->{'storageconfig'};

    my @revconfigs = sort {$b->{'IDX'} <=> $a->{'IDX'}} @$sconfigs;

    # Grab the global lock to prevent concurrency.
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	fatal("blockstore_vnodeDestroy: ".
	      "Could not get the blkalloc lock after a long time!");
    }

    # Run through blockstore removal commands (reversed creation list).
    foreach my $sconf (@revconfigs) {
	my $cmd = $sconf->{'CMD'};
	if (exists($teardown_cmds{$cmd})) {
	    if ($teardown_cmds{$cmd}->($vnode_id, $sconf, $vnconfig) != 0) {
		TBScriptUnlock();
		fatal("blockstore_vnodeDestroy: ".
		      "Failed to execute teardown command: $cmd");
	    }
	} else {
	    TBScriptUnlock();
	    fatal("blockstore_vnodeDestroy: ".
		  "Don't know how to execute: $cmd");
	}
    }

    # Lastly, remove the vlan inteface.  That we only have one interface
    # and that it has the correct params was established at creation time.
    my $ifcfg = (@{$vnconfig->{'ifconfig'}})[0];
    my $vtag  = $ifcfg->{'VTAG'};
    my $viface = $VLAN_IFACE_PREFIX . $vtag;
    if (removeVlanInterface($viface) != 0) {
	TBScriptUnlock();
	fatal("blockstore_vnodeDestroy: ".
	      "Could not remove the vlan interface!");
    }

    TBScriptUnlock();
    return 0;
}

# blockstores don't "halt", but we'll signal that we did anyway.
sub vnodeHalt($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    libutil::setState("SHUTDOWN");
    $vnstates{$vnode_id} = VNODE_STATUS_STOPPED();

    return 0;
}

# Nothing to do...
sub vnodeExec($$$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private, $command) = @_;

    return 0;
}

# On the surface it would seem like this might apply to blockstore pseudo-VMs.
# Teardown and destroy do the work that this might do.
sub vnodeUnmount($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

#######################################################################
# package-local functions
#

#
# Run a FreeNAS CLI command, checking for a return error and other
# such things.  We check that the incoming verb is valid.  Command line
# argument string needs to be untainted or this will fail.
#
# Returns numberic code indicating success, failure, internal error.
#
sub runFreeNASCmd($$) {
    my ($verb, $argstr) = @_;

    if (!exists($cliverbs{$verb})) {
	warn("*** ERROR: blockstore_runFreeNASCmd: ".
	     "Invalid FreeNAS CLI verb: $verb");
	return -1;
    }

    print "DEBUG: blockstore_runFreeNASCmd:\n".
	"\trunning: $verb $argstr\n" if $debug;

    my $output = `$FREENAS_CLI $verb $argstr`;
    if ($? != 0) {
	print STDERR $output if $debug;
	warn("*** ERROR: blockstore_runFreeNASCmd: ".
	     "Error returned from FreeNAS CLI: $?");
	return -1;
    }

    if ($output =~ /"error": false/) {
	return 0;
    }

    print STDERR $output if $debug;
    return 1;
}

# Run our custom FreeNAS CLI to extract info.  
#
# Returns an array of hash references.  Each hash contains info from
# one line of output.  The hash keys are the field names from the
# header (first line of output).  The hash values are the
# corresponding pieces of data at each field location in a line.
sub parseFreeNASListing($) {
    my $verb = shift;
    my @retlist = ();

    # XXX: should check that a valid verb was passed in.

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
	    warn("*** WARNING: blockstore_parseFreeNASListing: ".
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

#
# Run through list of storage commands and execute them, checking
# for errors.  (Should have a lock before doing this.)
#
sub runBlockstoreCmds($$) {
    my ($vnode_id, $vnconfig) = @_;
    my $sconfigs = $vnconfig->{'storageconfig'};
    
    foreach my $sconf (@$sconfigs) {
	my $cmd = $sconf->{'CMD'};
	if (exists($setup_cmds{$cmd})) {
	    if ($setup_cmds{$cmd}->($vnode_id, $sconf, $vnconfig) != 0) {
		warn("*** ERROR: blockstore_runBlockstoreCmds: ".
		     "Failed to execute setup command: $cmd");
		return -1;
	    }
	} else {
	    warn("*** ERROR: blockstore_runBlockstoreCmds: ".
		 "Don't know how to execute: $cmd");
	    return -1;
	}
    }

    return 0;
}

# Yank information about blockstore slices out of FreeNAS.
# Note: this is an expensive call - may want to re-visit caching some of
# this later if performance becomes a problem.
sub getSliceList() {
    my $sliceshash = {};

    # Grab list of slices (iscsi extents) from FreeNAS
    my @slist = parseFreeNASListing($CLI_VERB_IST_EXTENT);

    # Just return if there are no slices.
    return if !@slist;

    # Go through each slice hash, culling out extra info.
    # Save hash in global list.  Throw out malformed stuff.
    foreach my $slice (@slist) {
	my ($pid,$eid,$volname) = parseSliceName($slice->{'name'});
	my ($bsid, $vnode_id) = parseSlicePath($slice->{'path'});
	if (!defined($pid) || !defined($bsid)) {
	    warn("*** WARNING: blockstore_getSliceList: ".
		 "malformed slice entry, skipping.");
	    next;
	}
	$slice->{'pid'} = $pid;
	$slice->{'eid'} = $eid;
	$slice->{'volname'} = $volname;
	$slice->{'bsid'} = $bsid;
	$slice->{'vnode_id'} = $vnode_id;
	$sliceshash->{$vnode_id} = $slice;
    }

    # Do the messy work of getting slice size info into mebibytes.
    calcSliceSizes($sliceshash);

    return $sliceshash;
}

# helper function.
# Slice names look like: 'iqn.<date>.<tld>.<domain>:<pid>:<eid>:<volname>'
sub parseSliceName($) {
    my $name = shift;
    my @parts = split(/:/, $name);
    if (scalar(@parts) != 4) {
	warn("*** WARNING: blockstore_parseSliceName: Bad slice name: $name");
	return undef;
    }
    shift @parts;
    return @parts;
}

# helper function.
# Paths look like this: '/mnt/<blockstore_id>/<vnode_id>' for file-based
# extent (slice), and 'zvol/<blockstore_id>/<vnode_id>' for zvol extents.
sub parseSlicePath($) {
    my $path = shift;

    my @parts = split(/\//, $path);
    shift @parts
	if (scalar(@parts) == 4 && !$parts[0]); # chomp leading slash part
    if (scalar(@parts) != 3 ||  $parts[0] !~ /^(mnt|zvol)$/i) {
	warn("*** WARNING: blockstore_parseSlicePath: ".
	     "malformed slice path: $path");
	return undef;
    }
    shift @parts;
    return @parts;
}

sub calcSliceSizes($) {
    my $sliceshash = shift;

    my @zvols = parseFreeNASListing($CLI_VERB_VOLUME);

    # Ugh... Have to look up size via the "volume" list for
    # zvol slices.
    foreach my $slice (values(%$sliceshash)) {
	my $bsid    = $slice->{'bsid'};
	my $vnode_id = $slice->{'vnode_id'};
	my $type    = lc($slice->{'type'});

	my $size = undef;

	if ($type eq "zvol") {
	    foreach my $zvol (@zvols) {
		print STDERR "DEBUG: volume: ". $zvol->{'vol_name'} ."\n";
		if ($zvol->{'vol_name'} eq "$bsid/$vnode_id") {
		    $size = $zvol->{'vol_size'};
		    last;
		}
	    }
	    if (!defined($size)) {
		warn("*** WARNING: blockstore_getSliceList: ".
		     "Could not find matching volume entry for ".
		     "zvol slice: $slice->{'name'}");
		next;
	    }
	    $size .= "B"; # Fix up units (value is \d{1,3}[TGM]).
	} elsif ($type eq "file") {
	    $size = $slice->{'filesize'};
	    $size =~ s/B$/iB/; # re-write with correct units.
	}
	$slice->{'size'} = convertToMebi($size);
    }
    return;
}

# Return information on all of the volume pools available on this host.
sub getPoolList() {
    my $poolh = {};
    my @pools = parseFreeNASListing($CLI_VERB_POOL);
    
    # Create hash with pool name as key.  Stuff in some sentinel values
    # in case we don't get a match from 'zpool list' below.
    foreach my $pool (@pools) {
	$pool->{'size'} = 0;
	$pool->{'avail'} = 0;
	$poolh->{$pool->{'volume_name'}} = $pool;
    }

    # Yuck - have to go after capacity and status info by calling the
    # 'zfs' command line utility since the CLI doesn't return this info.
    open(ZFS, "$ZFS_CMD list -H -o name,used,avail |") or
	die "Can't run 'zfs list'!";

    while (my $line = <ZFS>) {
	chomp $line;
	my ($pname, $pused, $pavail) = split(/\s+/, $line);
	next if $pname =~ /\//;  # filter out zvols.
	if (exists($poolh->{$pname})) {
	    my $pool = $poolh->{$pname};
	    $pused  = convertToMebi($pused);
	    $pavail = convertToMebi($pavail);
	    $pool->{'size'}  = $pused + $pavail;
	    $pool->{'avail'} = $pavail;
	} else {
	    warn("*** WARNING: blockstore_getPoolInfo: ".
		 "No FreeNAS entry for zpool: $pname");
	}
    }

    return $poolh;
}

# Allocate a slice based on information from Emulab Central
# XXX: Do 'sliceconfig' parameter checking.
sub allocSlice($$$) {
    my ($vnode_id, $sconf, $vnconfig) = @_;

    my $priv = $vnconfig->{'private'};

    my $slices = getSliceList();
    my $pools  = getPoolList();

    # XXX: What should we do if the slice is already there?
    if (exists($slices->{$vnode_id})) {
	warn("*** ERROR: blockstore_allocSlice: ".
	     "slice already exists: $vnode_id. Please clean up!");
	return -1;
    }

    # Does the requested pool exist?
    my $bsid = untaintHostname($sconf->{'BSID'});
    my $destpool;
    if (exists($pools->{$bsid})) {
	$destpool = $pools->{$bsid};
	$priv->{"bsid"} = $bsid; # save for future calls.
    } else {
	warn("*** ERROR: blockstore_allocSlice: ".
	     "Requested blockstore not found: $bsid!");
	return -1;
    }

    # Is there enough space on the requested blockstore?  If not, there is
    # a discrepancy between reality and the Emulab database.
    my $size = untaintNumber($sconf->{'VOLSIZE'});
    if ($size + $ZPOOL_LOW_WATERMARK > $destpool->{'avail'}) {
	warn("*** ERROR: blockstore_allocSlice: ". 
	     "Not enough space remaining on requested blockstore: $bsid");
	return -1;
    }

    # Allocate slice in zpool
    # XXX: check on size conversion.
    if (runFreeNASCmd($CLI_VERB_VOLUME, 
		      "add $bsid $vnode_id ${size}MB off") != 0)
    {
	warn("*** ERROR: blockstore_allocSlice: ".
	     "slice allocation failed!");
	return -1;
    }

    return 0;
}

# Setup device export.
sub exportSlice($$$) {
    my ($vnode_id, $sconf, $vnconfig) = @_;

    # Should only be one ifconfig entry - checked earlier.
    my $ifcfg   = (@{$vnconfig->{'ifconfig'}})[0];
    my $nmask   = $ifcfg->{'IPMASK'};
    my $cmask   = libutil::CIDRmask($nmask);
    my $network = libutil::ipToNetwork($ifcfg->{'IPADDR'}, $nmask);
    if (!$cmask || !$network) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Error calculating ip network information.");
	return -1;
    }
    
    # Extract info stored earlier.
    my $priv = $vnconfig->{'private'};
    my $bsid = $priv->{'bsid'};
    if (!defined($bsid)) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "blockstore ID not found - cannot proceed!");
	return -1;
    }

    # Scrub request - we only support SAN/iSCSI at this point.
    if (!exists($sconf->{'CLASS'}) || $sconf->{'CLASS'} ne $BS_CLASS_SAN) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "invalid or missing blockstore class!");
	return -1;
    }

    if (!exists($sconf->{'PROTO'}) || $sconf->{'PROTO'} ne $BS_PROTO_ISCSI) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "invalid or missing blockstore protocol!");
	return -1;
    }

    if (!exists($sconf->{'VOLNAME'})) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "missing volume name!");
	return -1;
    }
    my $volname = $sconf->{'VOLNAME'};

    if (!exists($sconf->{'UUID'}) || 
	!exists($sconf->{'UUID_TYPE'}) ||
	$sconf->{'UUID_TYPE'} ne $BS_UUID_TYPE_IQN)
    {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "bad UUID information!");
	return -1;
    }
    if ($sconf->{'UUID'} !~ /^([-\.:\w]+)$/) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "bad characters in UUID!");
	return -1;
    }
    my $iqn = $1; # untaint.

    # Create iSCSI extent
    if (runFreeNASCmd($CLI_VERB_IST_EXTENT, 
		      "add $iqn $bsid/$vnode_id") != 0)
    {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to create iSCSI extent!");
	return -1;
    }

    # Create iSCSI auth group
    my $tag = getNextAuthITag();
    if ($tag !~ /^(\d+)$/) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "bad tag returned from getNextAuthITag: $tag");
	return -1;
    }
    $tag = $1; # untaint.
    if (runFreeNASCmd($CLI_VERB_IST_AUTHI,
		      "add $tag ALL $network/$cmask") != 0)
    {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to create iSCSI auth group!");
	return -1;
    }

    # Create iSCSI target
    my $serial = genSerial();
    if (runFreeNASCmd($CLI_VERB_IST_TARGET,
		      "add $iqn $serial $ISCSI_GLOBAL_PORTAL ".
		      "$tag Auto -1") != 0)
    {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to create iSCSI target!");
	return -1;
    }

    # Bind iSCSI target to slice (extent)
    if (runFreeNASCmd($CLI_VERB_IST_ASSOC,
		      "add $iqn $iqn") != 0)
    {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to associate iSCSI target with extent!");
	return -1;
    }

    # All setup and exported!
    return 0;
}

# Helper function.
# Locate and return tag for given network, if it exists.
sub findAuthITag($$) {
    my ($subnet, $cidrmask) = @_;

    return undef
	if !defined($subnet) or !defined($cidrmask);

    my @authentries = parseFreeNASListing($CLI_VERB_IST_AUTHI);

    return undef
	if !@authentries;

    foreach my $authent (@authentries) {
	if ($authent->{'auth_network'} eq "$subnet/$cidrmask") {
	    return $authent->{'tag'};
	}
    }

    return undef;
}

# Helper function.
# Locate and return next unused tag ID for iSCSI initiator groups.
sub getNextAuthITag() {
    my @authentries = parseFreeNASListing($CLI_VERB_IST_AUTHI);

    my $maxtag = 1;

    return $maxtag
	if !@authentries;

    foreach my $authent (@authentries) {
	my $curtag = $authent->{'tag'};
	next if !defined($curtag) || $curtag !~ /^\d+$/;
	$maxtag = $curtag > $maxtag ? $curtag : $maxtag;
    }

    return $maxtag+1;
}

# Helper function - Generate a random serial number for an iSCSI target
sub genSerial() {
    my $rand_hex = join "", map { unpack "H*", chr(rand(256)) } 1..6;
    return $SER_PREFIX . $rand_hex;
}

# Helper function - make vlan interface name given some inputs.
sub mkVlanIfaceName($$$) {
    my ($piface, $pmac, $vtag) = @_;

    return undef
	if !$vtag;

    return $VLAN_IFACE_PREFIX . $vtag;
}

#
# Given a physical interface/mac and vlan tag, make a vlan interface.
#
sub createVlanInterface($$) {
    my ($vnode_id, $vnconfig) = @_;

    # Create the control network vlan interface
    my $ifconfigs     = $vnconfig->{'ifconfig'};
    if (@$ifconfigs != 1) {
	warn("*** ERROR: blockstore_createVlanInterface: ".
	     "Wrong number of network interfaces.  There can be only one!");
	return -1;
    }

    my $ifc = @$ifconfigs[0];

    if ($ifc->{'ITYPE'} ne "vlan") {
	warn("*** ERROR: blockstore_createVlanInterface: ".
	     "Interface must be of type 'vlan'!");
	return -1;
    }

    my $vtag   = $ifc->{'VTAG'};
    my $pmac   = $ifc->{'PMAC'};
    my $piface = $ifc->{'IFACE'};
    my $ip     = $ifc->{'IPADDR'};
    my $mask   = $ifc->{'IPMASK'};

    # Create vlan interface name
    my $viface = mkVlanIfaceName($piface,$pmac,$vtag);

    # Untaint stuff.
    if ($piface !~ /^([-\w]+)$/) {
	warn("*** ERROR: blockstore_createVlanInterface: ". 
	     "bad data physical interface name!");
	return -1;
    }
    $piface = $1;

    if ($pmac !~ /^([a-fA-F0-9:]+)$/) {
	warn("*** ERROR: blockstore_createVlanInterface: ". 
	     "bad data in physical mac address!");
	return -1;
    }
    $pmac = $1;

    if ($viface !~ /^([-\w]+)$/) {
	warn("*** ERROR: blockstore_createVlanInterface: ". 
	     "bad data in vlan interface name!");
	return -1;
    }
    $viface = $1;

    if ($vtag !~ /^(\d+)$/) {
	warn("*** ERROR: blockstore_createVlanInterface: ". 
	     "bad data in vlan tag!");
	return -1;
    }
    $vtag = $1;

    if ($ip !~ /^([\.\d]+)$/) {
	warn("*** ERROR: blockstore_setVlanInterfaceIPAddress: ". 
	     "bad data in IP address!");
	return -1;
    }
    $ip = $1;

    if ($mask !~ /^([\.\d]+)$/) {
	warn("*** ERROR: blockstore_setVlanInterfaceIPAddress: ". 
	     "bad characters in subnet!");
	return -1;
    }
    $mask = libutil::CIDRmask($1);

    # First, create the vlan interface:
    my $rval = runFreeNASCmd($CLI_VERB_VLAN,
			     "add $piface $viface $vtag");

    if ($rval != 0) {
	warn("*** ERROR: blockstore_createVlanInterface: ". 
	     "failure while creating vlan interface!");
	return -1;
    }

    # Next, set its address.
    $rval = runFreeNASCmd($CLI_VERB_IFACE,
			  "add $viface $viface $ip/$mask");

    if ($rval != 0) {
	warn("*** ERROR: blockstore_setVlanInterfaceIPAddress: ".
	     "failure while setting vlan interface parameters!");
	return -1;
    }


    return 0;
}

#
# Remove previously created VLAN interface.  This will also unblumb it
# from the network stack, so no need to call "interface del"
#
sub removeVlanInterface($) {
    my ($viface,) = @_;

    return -1
	unless defined($viface);

    my $rval = runFreeNASCmd($CLI_VERB_VLAN,
			     "del $viface");

    if ($rval != 0) {
	warn("*** ERROR: blockstore_removeVlanInterface: ".
	     "failure while removing vlan interface!");
	return -1;
    }

    return 0;
}

sub unexportSlice($$$) {
    my ($vnode_id, $sconf, $vnconfig) = @_;

    # Check that the slice exists.  Emit warning and return if not.
    my $slices = getSliceList();
    if (!exists($slices->{$vnode_id})) {
	warn("*** WARNING: blockstore_unexportSlice: ".
	     "Slice does not exist!");
	return 0;
    }

    # Should only be one ifconfig entry - checked earlier.
    my $ifcfg   = (@{$vnconfig->{'ifconfig'}})[0];
    my $nmask   = $ifcfg->{'IPMASK'};
    my $cmask   = libutil::CIDRmask($nmask);
    my $network = libutil::ipToNetwork($ifcfg->{'IPADDR'}, $nmask);
    if (!$cmask || !$network) {
	warn("*** ERROR: blockstore_unexportSlice: ".
	     "Error calculating ip network information.");
	return -1;
    }
    
    # All of the sanity checking was done when we first created and
    # exported this blockstore.  Assume nothing has changed...
    my $volname = $sconf->{'VOLNAME'};
    $sconf->{'UUID'} =~ /^([-\.:\w]+)$/;
    my $iqn = $1; # untaint.

    # Remove iSCSI extent.  This will also zap the target-to-extent
    # association.
    if (runFreeNASCmd($CLI_VERB_IST_EXTENT, 
		      "del $iqn") != 0)
    {
	warn("*** ERROR: blockstore_unexportSlice: ".
	     "Failed to remove iSCSI extent!");
	return -1;
    }

    # Remove iSCSI target.
    if (runFreeNASCmd($CLI_VERB_IST_TARGET,
		      "del $iqn") != 0)
    {
	warn("*** ERROR: blockstore_unexportSlice: ".
	     "Failed to remove iSCSI target!");
	return -1;
    }

    # Remove iSCSI auth group
    my $tag = findAuthITag($network,$cmask);
    if ($tag !~ /^(\d+)$/) {
	warn("*** ERROR: blockstore_unexportSlice: ".
	     "bad tag returned from findAuthITag: $tag");
	return -1;
    }
    $tag = $1; # untaint.
    if (runFreeNASCmd($CLI_VERB_IST_AUTHI,
		      "del $tag") != 0)
    {
	warn("*** ERROR: blockstore_unexportSlice: ".
	     "Failed to remove iSCSI auth group!");
	return -1;
    }

    # All torn down and unexported!
    return 0;
}

sub deallocSlice($$$) {
    my ($vnode_id, $sconf, $vnconfig) = @_;
    my $priv = $vnconfig->{'private'};

    # Check that the associated storage pool exists.
    my $pools = getPoolList();
    my $bsid = untaintHostname($sconf->{'BSID'});
    if (!exists($pools->{$bsid})) {
	warn("*** ERROR: blockstore_deallocSlice: ".
	     "Pool does not exist: $bsid");
	return -1;
    }

    # Get list of allocated slices and search for this one.
    my @slices = parseFreeNASListing($CLI_VERB_VOLUME);
    my $found = 0;
    foreach my $slice (@slices) {
	if ($slice->{'vol_name'} eq "$bsid/$vnode_id") {
	    $found = 1;
	    last;
	}
    }

    # If we don't find it, just emit a warning.
    if (!$found) {
	warn("*** WARNING: blockstore_deallocSlice: ".
	     "Slice does not exist: $bsid/$vnode_id");
	return 0;
    }

    # deallocate slice.
    if (runFreeNASCmd($CLI_VERB_VOLUME, 
		      "del $bsid $vnode_id") != 0)
    {
	warn("*** ERROR: blockstore_deallocSlice: ".
	     "slice removal failed!");
	return -1;
    }

    # Checks for lingering slices will be performed separately in
    # consistency checking routines, so we don't bother here to
    # check that the above actually succeeded.

    return 0;
}

# Required perl foo
1;
