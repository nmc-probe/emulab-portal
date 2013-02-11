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
my $FREENAS_CLI          = "$BINDIR/freenas-config";
my $CLI_VERB_IST_EXTENT  = "ist_extent";
my $CLI_VERB_IST_AUTHI   = "ist_authinit";
my $CLI_VERB_IST_TARGET  = "ist";
my $CLI_VERB_IST_ASSOC   = "ist_assoc";
my $CLI_VERB_VOLUME      = "volume";
my $CLI_VERB_POOL        = "pool";
my $ZPOOL_CMD            = "/sbin/zpool";
my $ZFS_CMD              = "/sbin/zfs";
my $ZPOOL_STATUS_UNKNOWN = "unknown";
my $ZPOOL_STATUS_ONLINE  = "online";
my $ZPOOL_LOW_WATERMARK  = 2 * 2**10; # 2GiB, expressed in MiB
my $FREENAS_MNT_PREFIX   = "/mnt";
my $ISCSI_GLOBAL_PORTAL  = 1;
my $SER_PREFIX           = "d0d0";

#
# Global variables
#
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
sub createVlanInterface($$$$);
sub setVlanInterfaceIPAddress($$$$);
sub allocSlice($$$);
sub exportSlice($$$);

# Dispatch table for storage configuration commands.
my %storageconf_cmds = (
    "SLICE"  => \&allocSlice,
    "EXPORT" => \&exportSlice
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
# tell whether or not we've already been here, done that.  Since
# FreeNAS uses memory filesystems for pretty much everything,
# we don't have to worry about removing the flag file on shutdown/reboot.
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

    # XXX: nothing to do?
    # XXX: Put in consistency checks.

    mysystem("touch /var/run/blockstore.ready");
    TBScriptUnlock();
    return 0;    
}

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
    # XXX: Put in network consistency checks.

    TBScriptUnlock();
    return 0;
}

sub rootPostConfig($)
{
    return 0;
}

sub vnodeState($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    my $err = 0;
    my $out = VNODE_STATUS_UNKNOWN();

    # if a mapping exists to a blockstore slice, then we are "running".
    if (mappingExists($vnode_id)) {
	$out = VNODE_STATUS_RUNNING();
    }
    return ($err, $out);
}

# Not much to do - just pull down the storage config and stash it for
# later calls.
sub vnodeCreate($$$$)
{
    my ($vnode_id, undef, $vnconfig, $private) = @_;
    my $attributes = $vnconfig->{'attributes'};
    my $vninfo = $private;

    my $vmid;
    if ($vnode_id =~ /^\w+\d+\-(\d+)$/) {
	$vmid = $1;
    }
    else {
	fatal("blockstore_vnodeCreate: bad vnode_id $vnode_id!");
    }
    $vninfo->{'vmid'} = $vmid;
    $private->{'vndir'} = VNODE_PATH() . "/$vnode_id";

    # Grab and stash away storageconfig stuff for this vnode.
    # XXX: this bit should ultimately be moved into mkvnode.pl
    my @tmp;
    fatal("getstorageconfig($vnode_id): $!")
	if (getstorageconfig(\@tmp));
    $vnconfig->{"storageconfig"} = \@tmp;

    return 0;
}

# Nothing to do presently.
sub vnodePreConfig($$$$$){
    my ($vnode_id, $vmid, $vnconfig, $private, $callback) = @_;
    my $vninfo = $private;

    return 0;
}

# Blockstore pseudo-VMs do not have a control network to setup.
sub vnodePreConfigControlNetwork($$$$$$$$$$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private,
	$ip,$mask,$mac,$gw, $vname,$longdomain,$shortdomain,$bossip) = @_;
    my $vninfo = $private;

    return 0;
}

# Here we actually do some work - setup the vlan interface.
sub vnodePreConfigExpNetwork($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $vninfo        = $private;
    my $ifconfigs     = $vnconfig->{'ifconfig'};

    if (@$ifconfigs != 1) {
	fatal("blockstore_vnodePreConfigExpNetwork: Wrong number of ".
	      "network interfaces.  There can be only one!");
    }

    my $ifc = $ifconfigs->[0];

    if ($ifc->['ITYPE'] ne "vlan") {
	fatal("blockstore_vnodePreConfigExpNetwork: ".
	      "interface type MUST be vlan!")
    }

    my $vtag  = $ifc->['VTAG'];
    my $pmac  = $ifc->['PMAC'];
    my $iface = $ifc->['IFACE'];
    my $ip    = $ifc->['IPADDR'];
    my $mask  = $ifc->['IPMASK'];

    # First, create the vlan interface
    if (createVlanInterface($vnode_id, $iface, $pmac, $vtag) != 0) {
	fatal("blockstore:vnodePreConfigExpNetwork: ".
	      "could not create vlan interface: $iface");
    }

    # Next, setup its IP parameters
    if (setVlanInterfaceIPAddress($vnode_id, $iface, $ip, $mask) != 0) {
	fatal("blockstore:vnodePreConfigExpNetwork: ".
	      "could not set IP parameters on interface: $iface");	
    }

    # XXX: not done.

    return 0
}

# Run through blockstore setup command sequence returned by
# 'storageconfig' tmcd call.  Hold the lock - we don't want
# concurrency with other blockstore pseudo-VMs!
sub vnodeConfigResources($$$$){
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $sconfigs = $vnconfig->{'storageconfig'};

    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	warn("*** ERROR: blockstore_allocSlice: ".
	     "Could not get the blkalloc lock after a long time!");
	return -1;
    }
    
    foreach my $sconf (@$sconfigs) {
	my $cmd = $sconf->{'CMD'};
	if (exists($storageconf_cmds{$cmd})) {
	    if ($storageconf_cmds{$cmd}->($vnode_id, $sconf, $vnconfig) != 0) {
		warn("*** ERROR: blockstore_vnodeConfigResources: ".
		     "Failed to execute setup command: $cmd");
		TBScriptUnlock();
		return -1;
	    }
	} else {
	    warn("*** ERROR: blockstore_vnodeCongfigResources: ".
		 "Don't know how to execute: $cmd");
	    TBScriptUnlock();
	    return -1;
	}
    }

    TBScriptUnlock();
    return 0;
}

# Nothing to do (yet).
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

    return 0;
}

# Nothing to do.
sub vnodePostConfig($)
{
    return 0;
}

# blockstores don't "reboot"
sub vnodeReboot($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

# When this is called, we remove the blockstore export and zap the
# vlan interface.
sub vnodeTearDown($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    # XXX: implement.
}

# When this is called, we remove the blockstore slice altogether.
sub vnodeDestroy($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $vninfo = $private;
    # XXX: implement.
}

# blockstores don't "halt"
sub vnodeHalt($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

# What would I implement here?
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

#
# package-local functions
#


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

# Yank information about blockstore slices out of FreeNAS.
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
# Slice names look like: '<pid>:<eid>:<volname>'
sub parseSliceName($) {
    my $name = shift;
    my @parts = split(/:/, $name);
    if (scalar(@parts) != 3) {
	warn("*** WARNING: blockstore_parseSliceName: Bad slice name: $name");
	return undef;
    }
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
	$slice->{'size'} = libutil::convertToMebi($size);
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
    # 'zfs' command line utility.
    open(ZFS, "$ZFS_CMD list -H -o name,used,avail |") or
	die "Can't run 'zfs list'!";

    while (my $line = <ZFS>) {
	chomp $line;
	my ($pname, $pused, $pavail) = split(/\s+/, $line);
	next if $pname =~ /\//;  # filter out zvols.
	if (exists($poolh->{$pname})) {
	    my $pool = $poolh->{$pname};
	    $pused  = libutil::convertToMebi($pused);
	    $pavail = libutil::convertToMebi($pavail);
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
sub allocSlice($$$) {
    my ($vnode_id, $sconf, $vnconfig) = @_;

    # 1) Grab slice lock
    # 2) Get pool info
    #    a) pool to allocate from is passed in.
    # 3) Get existing slice info
    # 4) Check if slice exists
    #    a) Do what if it does?
    # 5) Create slice if possible
    #    a) Enough free space?
    # 6) Return success/fail

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
    my $bsid = $sconf->{'BSID'};
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
    my $size = $sconf->{'VOLSIZE'};
    if ($size + $ZPOOL_LOW_WATERMARK > $destpool->{'avail'}) {
	warn("*** ERROR: blockstore_allocSlice: ". 
	     "Not enough space remaining on requested blockstore: $bsid");
	return -1;
    }

    # Allocate slice in zpool
    # XXX: check on size conversion.
    mysystem2("$FREENAS_CLI $CLI_VERB_VOLUME add ".
	      "$bsid $vnode_id ${size}MB off");
    if ($? != 0) {
	warn("*** ERROR: blockstore_allocSlice: ".
	     "Failed to create slice on $bsid: CLI exit code: $?");
	return -1;
    }

    return 0;    
}

# Setup device export.
# XXX: must do better parameter checking.
# XXX: convert FREENAS_CLI calls
sub exportSlice($$$) {
    my ($vnode_id, $sconf, $vnconfig) = @_;

    # Should only be one ifconfig entry - checked earlier.
    my $ifcfg   = (@{$vnconfig->{'ifconfig'}})[0];
    print Dumper($ifcfg);
    my $nmask   = $ifcfg->{'IPMASK'};
    my $cmask   = libutil::CIDRmask($nmask);
    my $network = libutil::ipToNetwork($ifcfg->{'IPADDR'}, $nmask);

    # Extract info stored earlier.
    my $priv = $vnconfig->{'private'};
    my $bsid = $priv->{'bsid'};
    if (!defined($bsid)) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "blockstore ID not found - cannot proceed!");
	return -1;
    }

    # throw out 'iqn' prefix.
    my @iqnparts = (split(/:/,$sconf->{'UUID'}));
    shift @iqnparts;
    my $iqnsuffix = join(":", @iqnparts);

    # Create iSCSI extent
    mysystem2("$FREENAS_CLI $CLI_VERB_IST_EXTENT add ".
	      "$iqnsuffix $bsid/$vnode_id");
    if ($? != 0) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to create iSCSI extent: CLI exit code: $?");
	return -1;
    }

    # Create iSCSI auth group
    my $tag = getNextAuthITag();
    if ($tag !~ /^\d+$/) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "bad tag returned from getNextAuthITag.");
	return -1;
    }
    mysystem2("$FREENAS_CLI $CLI_VERB_IST_AUTHI add ".
	      "$tag ALL $network/$cmask");
    if ($? != 0) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to create iSCSI auth group: CLI exit code: $?");
	return -1;
    }

    # Create iSCSI target
    my $serial = genSerial();
    mysystem2("$FREENAS_CLI $CLI_VERB_IST_TARGET add ".
	      "$iqnsuffix $serial $ISCSI_GLOBAL_PORTAL $tag Auto -1");
    if ($? != 0) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to create iSCSI target: CLI exit code: $?");
	return -1;
    }

    # Bind iSCSI target to slice (extent)
    mysystem2("$FREENAS_CLI $CLI_VERB_IST_ASSOC add ".
	      "$iqnsuffix $iqnsuffix");
    if ($? != 0) {
	warn("*** ERROR: blockstore_exportSlice: ".
	     "Failed to associate iSCSI target with extent: CLI exit code: $?");
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

# Helper function.
# Generate a random serial number for an iSCSI target
sub genSerial() {
    my $rand_hex = join "", map { unpack "H*", chr(rand(256)) } 1..6;
    return $SER_PREFIX . $rand_hex;
}

sub createVlanInterface($$$$) {
    my ($vnode_id, $iface, $pmac, $vtag) = @_

}

sub setVlanInterfaceIPAddress($$$$) {
    my ($vnode_id, $iface, $ip, $mask) = @_;

}

# Required perl foo
1;
