#!/usr/bin/perl -wT
#
# Copyright (c) 2008-2013 University of Utah and the Flux Group.
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
# Implements the libvnode API for Xen support in Emulab.
#
# Note that there is no distinguished first or last call of this library
# in the current implementation.  Every vnode creation (through mkvnode.pl)
# will invoke all the root* and vnode* functions.  It is up to us to make
# sure that "one time" operations really are executed only once.
#
# TODO:
# + Clear out old, incorrect state in /var/lib/xend.
#   Maybe have to do this when tearing down (killing) vnodes.
#
# + Make more robust, little turds of state still get left around
#   that wreak havoc on reboot.
#
# + Support image loading.
#
package libvnode_xen;
use Exporter;
@ISA    = "Exporter";
@EXPORT = qw( init setDebug rootPreConfig
              rootPreConfigNetwork rootPostConfig
	      vnodeCreate vnodeDestroy vnodeState
	      vnodeBoot vnodePreBoot vnodeHalt vnodeReboot
	      vnodeUnmount
	      vnodePreConfig vnodePreConfigControlNetwork
              vnodePreConfigExpNetwork vnodeConfigResources
              vnodeConfigDevices vnodePostConfig vnodeExec vnodeTearDown VGNAME
	    );
use vars qw($VGNAME);

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
# XXX needs to be implemented
         'vnodeUnmount' => \&vnodeUnmount,
         'vnodeReboot' => \&vnodeReboot,
# XXX needs to be implemented
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

# Pull in libvnode
BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }
use libutil;
use libgenvnode;
use libvnode;
use libtestbed;
use libsetup;

#
# Turn off line buffering on output
#
$| = 1;

#
# Load the OS independent support library. It will load the OS dependent
# library and initialize itself. 
# 

##
## Standard utilities and files section
##

my $BRCTL = "brctl";
my $IFCONFIG = "/sbin/ifconfig";
my $ETHTOOL = "/sbin/ethtool";
my $ROUTE = "/sbin/route";
my $SYSCTL = "/sbin/sysctl";
my $VLANCONFIG = "/sbin/vconfig";
my $MODPROBE = "/sbin/modprobe";
my $DHCPCONF_FILE = "/etc/dhcpd.conf";
my $NEW_DHCPCONF_FILE = "/etc/dhcp/dhcpd.conf";
my $RESTOREVM	= "$BINDIR/restorevm.pl";
my $LOCALIZEIMG	= "$BINDIR/localize_image";
my $IPTABLES	= "/sbin/iptables";
my $IPBIN	= "/sbin/ip";
my $NETSTAT     = "/bin/netstat";
my $IMAGEZIP    = "/usr/local/bin/imagezip";
my $IMAGEUNZIP  = "/usr/local/bin/imageunzip";
my $debug  = 0;

##
## Randomly chosen convention section
##

# global lock
my $GLOBAL_CONF_LOCK = "xenconf";

# default image to load on logical disks
# Just symlink /boot/vmlinuz-xenU and /boot/initrd-xenU
# to the kernel and ramdisk you want to use by default.
my %defaultImage = (
    'name'      => "emulab-ops-emulab-ops-XEN-STD",
    'kernel'    => "/boot/vmlinuz-xenU",
    'ramdisk'   => "/boot/initrd-xenU",
    'OSVERSION' => "any",
    'PARTOS'    => "Linux",
    'ISPACKAGE' => 0,
);

# where all our config files go
my $VMDIR = "/var/emulab/vms/vminfo";
my $XENDIR = "/var/xen";

# Extra space for restore.
my $EXTRAFS = "/capture";

# Extra space for metadata between reloads.
my $METAFS = "/metadata";

# Xen LVM volume group name. Accessible outside this file.
$VGNAME = "xen-vg";
# So we can ask this from outside;
sub VGNAME()  { return $VGNAME; }

##
## Indefensible, arbitrary constant section
##

# Maximum vnodes per physical host, used to size memory and disks
my $MAX_VNODES = 32;

# Minimum GB of disk per vnode
my $MIN_GB_DISK = 6;

# Minimum MB of memory per vnode
my $MIN_MB_VNMEM = 64;

# Minimum memory for dom0
my $MIN_MB_DOM0MEM = 256;

# Minimum acceptible size (in GB) of LVM VG for domUs.
my $XEN_MIN_VGSIZE = ($MAX_VNODES * $MIN_GB_DISK);

# XXX fixed-for-now LV size for all logical disks
my $XEN_LDSIZE = $MIN_GB_DISK;

# IFBs
my $IFBDB      = "/var/emulab/db/ifbdb";
# Kernel auto-creates only two! Sheesh, why a fixed limit?
my $MAXIFB     = 1024;

# Route tables for tunnels
my $RTDB           = "/var/emulab/db/rtdb";
my $RTTABLES       = "/etc/iproute2/rt_tables";
# Temporary; later kernel version increases this.
my $MAXROUTETTABLE = 255;

# LVM snapshots suck.
my $DOSNAP = 0;

# Use openvswitch for gre tunnels.
my $OVSCTL   = "/usr/local/bin/ovs-vsctl";
my $OVSSTART = "/usr/local/share/openvswitch/scripts/ovs-ctl";

#
# Information about the running Xen hypervisor
#
my %xeninfo = ();

# Local functions
sub findRoot();
sub copyRoot($$);
sub createRootDisk($);
sub createAuxDisk($$);
sub replace_hacks($);
sub disk_hacks($);
sub configFile($);
sub domain0Memory();
sub totalMemory();
sub hostIP($);
sub createDHCP();
sub addDHCP($$$$);
sub subDHCP($$);
sub restartDHCP();
sub formatDHCP($$$);
sub fixupMac($);
sub createControlNetworkScript($$$);
sub createExpNetworkScript($$$$$$$);
sub createTunnelScript($$$$);
sub createExpBridges($$$);
sub destroyExpBridges($$);
sub domainStatus($);
sub domainExists($);
sub addConfig($$$);
sub createXenConfig($$);
sub readXenConfig($);
sub lookupXenConfig($$);
sub getXenInfo();
sub AllocateIFBs($$$);
sub InitializeRouteTable();
sub AllocateRouteTable($);
sub LookupRouteTable($);
sub FreeRouteTable($);

sub getXenInfo()
{
    open(XM,"xm info|") 
        or die "getXenInfo: could not run 'xm info': $!";

    while (<XM>) {
	    chomp;
	    /^(\S+)\s*:\s+(.*)$/;
	    $xeninfo{$1} = $2;
    }
    
    close XM;
}

sub init($)
{
    my ($pnode_id,) = @_;

    makeIfaceMaps();
    makeBridgeMaps();
    getXenInfo();

    return 0;
}

sub setDebug($)
{
    $debug = shift;
    libvnode::setDebug($debug);
    print "libvnode_xen: debug=$debug\n"
	if ($debug);
}

#
# Called on each vnode, but should only be executed once per boot.
# We use a file in /var/run (cleared on reboots) to ensure this.
#
sub rootPreConfig()
{
    #
    # Haven't been called yet, grab the lock and double check that someone
    # didn't do it while we were waiting.
    #
    if (! -e "/var/run/xen.ready") {
	my $locked = TBScriptLock($GLOBAL_CONF_LOCK,
				  TBSCRIPTLOCK_GLOBALWAIT(), 900);
	if ($locked != TBSCRIPTLOCK_OKAY()) {
	    return 0
		if ($locked == TBSCRIPTLOCK_IGNORE());
	    print STDERR "Could not get the xeninit lock after a long time!\n";
	    return -1;
	}
    }
    if (-e "/var/run/xen.ready") {
        TBScriptUnlock();
        return 0;
    }
    
    print "Configuring root vnode context\n";

    #
    # Start the Xen daemon if not running.
    # There doesn't seem to be a sure fire way to tell this.
    # However, one of the important things xend should do for us is
    # set up a bridge device for the control network, so we look for this.
    # The bridge should have the same name as the control network interface.
    #
    my ($cnet_iface,undef,undef,undef,undef,undef,$cnet_gw) = findControlNet();
    if (!existsBridge($cnet_iface)) {
	print "Starting xend and configuring cnet bridge...\n"
	    if ($debug);
	mysystem("/usr/sbin/xend start");

	#
	# xend tends to lose the default route, so make sure it exists.
	#
	system("route del default >/dev/null 2>&1");
	mysystem("route add default gw $cnet_gw");
    }

    # For tunnels
    mysystem("$MODPROBE openvswitch");
    mysystem("$OVSSTART --delete-bridges start");

    #
    # We use xen's antispoofing when constructing the guest control net
    # interfaces. This is most useful on a shared host, but no harm
    # in doing it all the time. 
    #
    mysystem("$IPTABLES -P FORWARD DROP");
    mysystem("$IPTABLES -F FORWARD");
    mysystem("$IPTABLES -A FORWARD ".
	     "-m physdev --physdev-in $cnet_iface -j ACCEPT");

    mysystem("$MODPROBE ifb numifbs=$MAXIFB");

    # Create a DB to manage them. 
    my %MDB;
    if (!dbmopen(%MDB, $IFBDB, 0660)) {
	print STDERR "*** Could not create $IFBDB\n";
	TBScriptUnlock();
	return -1;
    }
    for (my $i = 0; $i < $MAXIFB; $i++) {
	$MDB{"$i"} = ""
	    if (!defined($MDB{"$i"}));
    }
    dbmclose(%MDB);
    
    #
    # Ensure that LVM is loaded in the kernel and ready.
    #
    print "Enabling LVM...\n"
	if ($debug);

    # We assume our kernels support this.
    mysystem2("$MODPROBE dm-snapshot");
    if ($?) {
	print STDERR "ERROR: could not load snaphot module!\n";
	TBScriptUnlock();
	return -1;
    }

    #
    # See if our LVM volume group for VMs exists and create it if not.
    #
    my $vg = `vgs | grep $VGNAME`;
    if ($vg !~ /^\s+${VGNAME}\s/) {
	print "Creating volume group...\n"
	    if ($debug);

	#
	# Find available devices of sufficient size, prepare them,
	# and incorporate them into a volume group.
	#
	my $blockdevs = "";
	my %devs = libvnode::findSpareDisks();
	my $totalSize = 0;
	foreach my $dev (keys(%devs)) {
	    if (defined($devs{$dev}{"size"})) {
		$blockdevs .= " /dev/$dev";
		$totalSize += $devs{$dev}{"size"};
	    }
	    else {
		foreach my $part (keys(%{$devs{$dev}})) {
		    $blockdevs .= " /dev/${dev}${part}";
		    $totalSize += $devs{$dev}{$part}{"size"};
		}
	    }
	}
	if ($blockdevs eq '') {
	    print STDERR "ERROR: findSpareDisks found no disks for LVM!\n";
	    TBScriptUnlock();
	    return -1;
	}
		    
	mysystem("pvcreate $blockdevs");
	mysystem("vgcreate $VGNAME $blockdevs");

	my $size = lvmVGSize($VGNAME);
	if ($size < $XEN_MIN_VGSIZE) {
	    print STDERR "ERROR: physical disks not big enough to support".
		" VMs ($size < $XEN_MIN_VGSIZE)\n";
	    TBScriptUnlock();
	    return -1;
	}
    }

    #
    # Make sure our volumes are active -- they seem to become inactive
    # across reboots
    #
    mysystem("vgchange -a y $VGNAME");

    #
    # For compatibility with existing (physical host) Emulab images,
    # the physical host provides DHCP info for the vnodes.  So we create
    # a skeleton dhcpd.conf file here.
    #
    # Note that we must first add an alias to the control net bridge so
    # that we (the physical host) are in the same subnet as the vnodes,
    # otherwise dhcpd will fail.
    #
    if (system("ifconfig $cnet_iface:1 | grep -q 'inet addr'")) {
	print "Creating $cnet_iface:1 alias...\n"
	    if ($debug);
	my ($vip,$vmask) = domain0ControlNet();
	mysystem("ifconfig $cnet_iface:1 $vip netmask $vmask");
    }

    print "Creating dhcp.conf skeleton...\n"
        if ($debug);
    createDHCP();

    print "Creating scratch FS ...\n";
    if (createExtraFS($EXTRAFS, $VGNAME, "50G")) {
	TBScriptUnlock();
	return -1;
    }
    print "Creating metadata FS ...\n";
    if (createExtraFS($METAFS, $VGNAME, "10M")) {
	TBScriptUnlock();
	return -1;
    }
    if (InitializeRouteTables()) {
	print STDERR "*** Could not initialize routing table DB\n";
	TBScriptUnlock();
	return -1;
    }
    mysystem("touch /var/run/xen.ready");
    TBScriptUnlock();
    return 0;
}

sub rootPreConfigNetwork($$$$)
{
    my ($vnode_id, undef, $vnconfig, $private) = @_;
    my @node_ifs = @{ $vnconfig->{'ifconfig'} };
    my @node_lds = @{ $vnconfig->{'ldconfig'} };

    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }

    createDHCP()
	if (! -e $DHCPCONF_FILE && ! -e $NEW_DHCPCONF_FILE);

    #
    # If we blocked, it would be because vnodes have come or gone,
    # so we need to rebuild the maps.
    #
    makeIfaceMaps();
    makeBridgeMaps();

    TBScriptUnlock();
    return 0;
bad:
    TBScriptUnlock();
    return -1;
}

sub rootPostConfig($)
{
    return 0;
}

#
# Create the basic context for the VM and give it a unique ID for identifying
# "internal" state.  If $raref is set, then we are in a RELOAD state machine
# and need to walk the appropriate states.
#
sub vnodeCreate($$$$)
{
    my ($vnode_id, undef, $vnconfig, $private) = @_;
    my $attributes = $vnconfig->{'attributes'};
    my $imagename = $vnconfig->{'image'};
    my $raref = $vnconfig->{'reloadinfo'};
    my $vninfo = $private;
    my %image = %defaultImage;
    my $imagemetadata;
    my $lvname;
    my $inreload = 0;

    my $vmid;
    if ($vnode_id =~ /^\w+\d+\-(\d+)$/) {
	$vmid = $1;
    }
    else {
	fatal("xen_vnodeCreate: bad vnode_id $vnode_id!");
    }
    $vninfo->{'vmid'} = $vmid;

    #
    # We need to lock while messing with the image.
    #
    my $imagelockname = "xenimage." .
	(defined($imagename) ? $imagename : $defaultImage{'name'});
    if (TBScriptLock($imagelockname, TBSCRIPTLOCK_GLOBALWAIT(), 1800)
	!= TBSCRIPTLOCK_OKAY()) {
	fatal("Could not get $imagelockname lock after a long time!");
    }

    #
    # No image specified, use a default based on the dom0 OS.
    #
    if (!defined($imagename)) {
	$lvname = $image{'name'};
	
	#
	# Setup the default image now.
	# XXX right now this is a hack where we just copy the dom0
	# filesystem and clone (snapshot) that.
	#
	$imagename = $defaultImage{'name'};
	print STDERR "xen_vnodeCreate: ".
	    "no image specified, using default ('$imagename')\n";

	$lvname = "image+" . $imagename;
	if (!findLVMLogicalVolume($lvname)) {
	    createRootDisk($imagename);
	}
	$imagemetadata = \%defaultImage;
    }
    elsif (!defined($raref)) {
	#
	# Boot existing image. The base volume has to exist, since we do
	# not have any reload info to get it.
	#
	$lvname = "image+" . $imagename;
	if (!findLVMLogicalVolume($lvname)) {
	    TBScriptUnlock();
	    fatal("xen_vnodeCreate: ".
		  "cannot find logical volume for $lvname, and no reload info");
	}
    }
    else {
	$lvname = "image+" . $imagename;
	$inreload = 1;

	print STDERR "xen_vnodeCreate: loading image '$imagename'\n";

	# Tell stated we are getting ready for a reload
	libutil::setState("RELOADSETUP");

	#
	# Immediately drop into RELOADING before calling createImageDisk as
	# that is the place where any image will be downloaded from the image
	# server and we want that download to take place in the longer timeout
	# period afforded by the RELOADING state.
	#
	libutil::setState("RELOADING");

	if (createImageDisk($imagename, $vnode_id, $raref)) {
	    TBScriptUnlock();
	    fatal("xen_vnodeCreate: ".
		  "cannot create logical volume for $imagename");
	}
    }

    #
    # Load this from disk.
    #
    if (!defined($imagemetadata)) {
	if (LoadImageMetadata($imagename, \$imagemetadata)) {
	    TBScriptUnlock();
	    fatal("xen_vnodeCreate: ".
		  "cannot load image metadata for $imagename");
	}
    }

    #
    # See if the image is really a package.
    #
    if (exists($imagemetadata->{'ISPACKAGE'}) && $imagemetadata->{'ISPACKAGE'}){
	my $imagepath = lvmVolumePath($lvname);
	# In case of reboot.
	mysystem("mkdir -p /mnt/$imagename")
	    if (! -e "/mnt/$imagename");
	mysystem("mount $imagepath /mnt/$imagename")
	    if (! -e "/mnt/$imagename/.mounted");

	mysystem2("$RESTOREVM -t $VMDIR/$vnode_id $vnode_id /mnt/$imagename");
	if ($?) {
	    mysystem2("umount /mnt/$imagename");
	    TBScriptUnlock();
	    fatal("xen_vnodeCreate: ".
		  "cannot restore logical volumes from $imagename");
	}
	mysystem2("umount /mnt/$imagename");
	
	#
	# All of the lvms are created and a new xm.conf created.
	# Read that xm.conf in so we can figure out what lvms we
	# need to delete later (recreate the disks array). 
	#
	my $conf = configFile($vnode_id);
	my $aref = readXenConfig($conf);
	if (!$aref) {
	    TBScriptUnlock();
	    fatal("xen_vnodeCreate: ".
		  "Cannot read restored config file from $conf");
	}
	$vninfo->{'cffile'} = $aref;
	
	my $disks = parseXenDiskInfo($vnode_id, $aref);
	if (!defined($disks)) {
	    TBScriptUnlock();
	    fatal("xen_vnodeCreate: Could not restore disk info from $conf");
	}
	$private->{'disks'} = $disks;
	TBScriptUnlock();
	goto done;
    }

    #
    # We get the OS and version from loadinfo.
    #
    my $vdiskprefix = "sd";	# yes, this is right for FBSD too
    my $os;
    
    if ($imagemetadata->{'PARTOS'} =~ /freebsd/i) {
	$os = "FreeBSD";
	my $kernel = ExtractKernelFromFreeBSDImage($lvname, "$VMDIR/$vnode_id");
	    
	if (!defined($kernel)) {
	    if ($imagemetadata->{'OSVERSION'} >= 9) {
		$kernel = "/boot/freebsd9/kernel";
	    }
	    elsif ($imagemetadata->{'OSVERSION'} >= 8) {
		$kernel = "/boot/freebsd8/kernel";
	    }
	    else {
		$kernel = "/boot/freebsd/kernel";
	    }
	    if (! -e $kernel) {
		fatal("libvnode_xen: ".
		      "no FreeBSD kernel for '$imagename' on $vnode_id");
	    }
	}
	$image{'kernel'} = $kernel;
	undef $image{'ramdisk'};
    }
    else {
	$os = "Linux";

	if ($imagemetadata->{'PARTOS'} =~ /fedora/i &&
	    $imagemetadata->{'OSVERSION'} >= 8 &&
	    $imagemetadata->{'OSVERSION'} < 9) {
	    $image{'kernel'}  = "/boot/fedora8/vmlinuz-xenU";
	    $image{'ramdisk'} = "/boot/fedora8/initrd-xenU";
	}
	elsif ($imagename ne $defaultImage{'name'}) {
	    #
	    # See if we can dig the kernel out from the image.
	    #
	    my ($kernel,$ramdisk) =
		ExtractKernelFromLinuxImage($lvname, "$VMDIR/$vnode_id");

	    if (defined($kernel)) {
		$image{'kernel'}  = $kernel;
		$image{'ramdisk'} = $ramdisk;

		#
		# If this is an Ubuntu ramdisk, we have to make sure it
		# will boot as a XEN guest, by changing the ramdisk. YUCK!
		#
		if ($imagemetadata->{'PARTOS'} =~ /ubuntu/i ||
		    $imagename =~ /ubuntu/i ||
		    system("strings $kernel | grep -q -i ubuntu") == 0) {
		    if (FixRamFs($vnode_id, $ramdisk)) {
			TBScriptUnlock();
			fatal("xen_vnodeCreate: Failed to fix ramdisk");
		    }
		}
	    }
	    # Use the booted kernel. Works sometimes. 
	}
	if ($xeninfo{xen_major} >= 4) {
	    $vdiskprefix = 'xvd';
	}
    }
    $private->{'os'} = $os;

    # All of the disk stanzas for the config file.
    my @alldisks = ();
    # Cache the config file, but will read it later.
    $private->{'disks'} = {};

    #
    # The root disk.
    #
    my $rootvdisk  = $vdiskprefix . "a";
    my $rootvndisk = lvmVolumePath($vnode_id);
    my $rootstanza = "phy:$rootvndisk,$rootvdisk,w";
    push(@alldisks, "'$rootstanza'");

    #
    # Since we may have (re)loaded a new image for this vnode, check
    # and make sure the vnode snapshot disk is associated with the
    # correct image.  Otherwise destroy the current vnode LVM so it
    # will get correctly associated below.
    #
    if (findLVMLogicalVolume($vnode_id)) {
	my $olvname = findLVMOrigin($vnode_id);
	if ($olvname ne $lvname) {
	    if (mysystem2("lvremove -f $VGNAME/$vnode_id")) {
		TBScriptUnlock();
		fatal("xen_vnodeCreate: ".
		      "could not destroy old disk for $vnode_id");
	    }
	}
    }

    #
    # Create the snapshot LVM.
    #
    if (!findLVMLogicalVolume($vnode_id)) {
	my $basedisk = lvmVolumePath($lvname);
	if ($DOSNAP) {
	    if (mysystem2("lvcreate -s -L ".
			  "${XEN_LDSIZE}G -n $vnode_id $basedisk")) {
		TBScriptUnlock();
		fatal("libvnode_xen: could not create disk for $vnode_id");
	    }
	}
	else {
	    #
	    # Need to create a new disk for the container. But lets see
	    # if we have a disk cached. We still have the imagelock at
	    # this point.
	    #
	    if (my (@files) = glob("/dev/$VGNAME/_C_${imagename}_*")) {
		#
		# Grab the first file and rename it. It becomes ours.
		# Then drop the lock.
		#
		my $file = $files[0];
		if (mysystem2("lvrename $file $rootvndisk")) {
		    TBScriptUnlock();
		    fatal("libvnode_xen: could not rename cache file");
		}
	    }
	    else {
		my $lv_size = lvSize($basedisk);
		if (!defined($lv_size)) {
		    TBScriptUnlock();
		    fatal("libvnode_xen: could not get size of $basedisk");
		}
		if (mysystem2("lvcreate -L ${lv_size} -n $vnode_id $VGNAME")) {
		    TBScriptUnlock();
		    fatal("libvnode_xen: could not create disk for $vnode_id");
		}
		#
		# Hacky attempt to determine if its a freebsd or linux disk.
		#
		mysystem2("$IMAGEZIP -i -b $basedisk > /dev/null 2>&1");
		my $ptypeopt = ($? ? "-l" : "-b");
	    
		mysystem2("nice $IMAGEZIP $ptypeopt $basedisk - | ".
			  "nice $IMAGEUNZIP -f -o -W 128 - $rootvndisk");
		if ($?) {
		    TBScriptUnlock();
		    fatal("libvnode_xen: could no clone $basedisk");
		}
	    }
	}
    }
    # Mark the lvm as created, for cleanup on error.
    $private->{'disks'}->{$vnode_id} = $vnode_id;

    #
    # The rest of this can proceed in parallel with other VMs.
    #
    TBScriptUnlock();

    my $auxchar  = ord('b');
    #
    # Create a swap disk.
    #
    if ($os eq "FreeBSD") {
	my $auxlvname = "${vnode_id}.swap";
	my $vndisk = lvmVolumePath($auxlvname);
	
	if (!findLVMLogicalVolume($auxlvname)) {
	    if (createAuxDisk($auxlvname, "2G")) {
		fatal("libvnode_xen: could not create swap disk");
	    }
	    #
	    # Mark it as a linux swap partition. 
	    #
	    if (mysystem2("echo ',,S' | sfdisk $vndisk -N0")) {
		fatal("libvnode_xen: could not partition swap disk");
	    }
	}
	my $vdisk  = $vdiskprefix . chr($auxchar++);
	my $stanza = "phy:$vndisk,$vdisk,w";

	$private->{'disks'}->{$auxlvname} = $auxlvname;
	push(@alldisks, "'$stanza'");
    }

    #
    # Create aux disks.
    #
    if (exists($attributes->{'XEN_EXTRADISKS'})) {
	my @list = split(",", $attributes->{'XEN_EXTRADISKS'});
	foreach my $disk (@list) {
	    my ($name,$size) = split(":", $disk);

	    my $auxlvname = "${vnode_id}.${name}";
	    if (!findLVMLogicalVolume($auxlvname)) {
		if (createAuxDisk($auxlvname, $size)) {
		    fatal("libvnode_xen: could not create aux disk: $name");
		}
	    }
	    my $vndisk = lvmVolumePath($auxlvname);
	    my $vdisk  = $vdiskprefix . chr($auxchar++);
	    my $stanza = "phy:$vndisk,$vdisk,w";

	    $private->{'disks'}->{$auxlvname} = $auxlvname;
	    push(@alldisks, "'$stanza'");
	}
    }
    print "All disks: @alldisks\n" if ($debug);

    #
    # Create the config file and fill in the disk/filesystem related info.
    # Since we don't want to leave a partial config file in the event of
    # a failure down the road, we just accumulate the config info in a string
    # and write it out right before we boot.
    #
    # BSD stuff inspired by:
    # http://wiki.freebsd.org/AdrianChadd/XenHackery
    #
    $vninfo->{'cffile'} = [];

    my $kernel = $image{'kernel'};
    my $ramdisk = $image{'ramdisk'};

    addConfig($vninfo, "# Xen configuration script for $os vnode $vnode_id", 2);
    addConfig($vninfo, "name = '$vnode_id'", 2);
    addConfig($vninfo, "kernel = '$kernel'", 2);
    addConfig($vninfo, "ramdisk = '$ramdisk'", 2)
	if (defined($ramdisk));
    addConfig($vninfo, "disk = [" . join(",", @alldisks) . "]", 2);

    if ($os eq "FreeBSD") {
	addConfig($vninfo, "extra = 'boot_verbose=1" .
		  ",vfs.root.mountfrom=ufs:/dev/da0a".
		  ",kern.bootfile=/boot/kernel/kernel'", 2);
    } else {
	addConfig($vninfo, "root = '/dev/$rootvdisk ro'", 2);
	addConfig($vninfo, "extra = 'console=hvc0 xencons=tty'", 2);
    }
  done:

    #
    # We allow the server to tell us how many VCPUs to allocate to the
    # guest. 
    #
    if (exists($attributes->{'VM_VCPUS'}) && $attributes->{'VM_VCPUS'} > 1) {
	addConfig($vninfo, "vcpus = " . $attributes->{'VM_VCPUS'}, 2);
    }
    
    #
    # Finish off the state transitions as necessary.
    #
    if ($inreload) {
	libutil::setState("RELOADDONE");
	sleep(4);
	libutil::setState("SHUTDOWN");
    }

    return $vmid;
}

#
# The logical disk has been created.
# Here we just mount it and invoke the callback.
#
# XXX note that the callback only works when we can mount the VM OS's
# filesystems!  Since all we do right now is Linux, this is easy.
#
sub vnodePreConfig($$$$$){
    my ($vnode_id, $vmid, $vnconfig, $private, $callback) = @_;
    my $vninfo = $private;
    my $retval = 0;

    #
    # XXX vnodeCreate is not called when a vnode was halted or is rebooting.
    # In that case, we read in any existing config file and restore the
    # disk info. 
    #
    if (!exists($vninfo->{'cffile'})) {
	my $aref = readXenConfig(configFile($vnode_id));
	if (!$aref) {
	    fatal("vnodePreConfig: no Xen config for $vnode_id!");
	}
	$vninfo->{'cffile'} = $aref;

	#
	# And, we need to recover the disk info from the config file.
	#
	my $disks = parseXenDiskInfo($vnode_id, $aref);
	if (!defined($disks)) {
	    fatal("vnodePreConfig: Could not restore disk info from config");
	}
	$private->{'disks'} = $disks;
    }
    return 0
	if (!exists($vninfo->{'os'}));

    #
    # XXX can only do the rest for nodes whose files systems we can mount.
    #
    return 0
	if (! ($vninfo->{'os'} eq "Linux" || $vninfo->{'os'} eq "FreeBSD"));
    
    mkpath(["/mnt/xen/$vnode_id"]);
    my $dev = lvmVolumePath($vnode_id);
    my $vnoderoot = "/mnt/xen/$vnode_id";

    #
    # We rely on the UFS module (with write support compiled in) to
    # deal with FBSD filesystems. 
    #
    if ($vninfo->{'os'} eq "FreeBSD") {
	mysystem("mount -t ufs -o ufstype=44bsd $dev $vnoderoot");
    }
    else {
	mysystem("mount $dev $vnoderoot");
    }

    # XXX We need to get rid of this or get it from tmcd!
    if (! -e "$vnoderoot/etc/emulab/genvmtype") {
	mysystem2("echo 'xen' > $vnoderoot/etc/emulab/genvmtype");
	goto bad
	    if ($?);
    }

    # Use the physical host pubsub daemon
    my (undef, $ctrlip) = findControlNet();
    if (!$ctrlip || $ctrlip !~ /^(\d+\.\d+\.\d+\.\d+)$/) {
	if ($?) {
	    print STDERR
		"vnodePreConfig: could not get control net IP for $vnode_id";
	    goto bad;
	}
    }

    #
    # For FreeBSD, we would have to mount the /var partition. 
    #
    if ($vninfo->{'os'} ne "FreeBSD") {
	# Should be handled in libsetup.pm, but just in case
	if (! -e "$vnoderoot/var/emulab/boot/localevserver" ) {
	    mysystem2("echo '$ctrlip' > $vnoderoot/var/emulab/boot/localevserver");
	    goto bad
		if ($?);
	}
	# XXX this should no longer be needed, but just in case
	if (! -e "$vnoderoot/var/emulab/boot/vmname" ) {
	    mysystem2("echo '$vnode_id' > $vnoderoot/var/emulab/boot/vmname");
	    goto bad
		if ($?);
	}
    }
    else {
	if (-e "$vnoderoot/etc/dumpdates") {
	    mysystem2("sed -i -e 's;^/dev/[ad][da][04]s1;/dev/da0;' ".
		      "  $vnoderoot/etc/dumpdates");
	    goto bad
		if ($?);
	}
	mysystem2("sed -i -e 's;^/dev/[ad][da][04]s1;/dev/da0;' ".
		  "  $vnoderoot/etc/fstab");
	goto bad
	    if ($?);
    }
    #
    # We have to do what slicefix does when it localizes an image.
    #
    mysystem2("$LOCALIZEIMG $vnoderoot");
    goto bad
	if ($?);
    
    $retval = &$callback($vnoderoot);
  bad:
    mysystem("umount $dev");
    return $retval;
}

#
# Configure the control network for a vnode.
#
# XXX for now, I just perform all the actions here til everything is working.
# This means they cannot easily be undone if something fails later on.
#
sub vnodePreConfigControlNetwork($$$$$$$$$$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private,
	$ip,$mask,$mac,$gw, $vname,$longdomain,$shortdomain,$bossip) = @_;
    my $vninfo = $private;

    if (!exists($vninfo->{'cffile'})) {
	die("libvnode_xen: vnodePreConfig: no state for $vnode_id!?");
    }
    my $network = inet_ntoa(inet_aton($ip) & inet_aton($mask));

    # Now allow routable control network.
    my $isroutable = isRoutable($ip);

    my $fmac = fixupMac($mac);
    # Note physical host control net IF is really a bridge
    my ($cbridge) = findControlNet();
    my $cscript = "$VMDIR/$vnode_id/cnet-$mac";

    # Save info for the control net interface for config file.
    $vninfo->{'cnet'} = {};
    $vninfo->{'cnet'}->{'mac'} = $fmac;
    $vninfo->{'cnet'}->{'bridge'} = $cbridge;
    $vninfo->{'cnet'}->{'script'} = $cscript;
    $vninfo->{'cnet'}->{'ip'} = $ip;

    # Create a network config script for the interface
    my $stuff = {'name' => $vnode_id,
		 'ip' => $ip,
		 'hip' => $gw,
		 'fqdn', => $longdomain,
		 'mac' => $fmac};
    createControlNetworkScript($vmid, $stuff, $cscript);

    # Create a DHCP entry
    $vninfo->{'dhcp'} = {};
    $vninfo->{'dhcp'}->{'name'} = $vnode_id;
    $vninfo->{'dhcp'}->{'ip'} = $ip;
    $vninfo->{'dhcp'}->{'mac'} = $fmac;

    # a route to reach the vnodes. Do it for the entire network,
    # and no need to remove it.
    if (!$isroutable && system("$NETSTAT -r | grep -q $network")) {
	mysystem2("$ROUTE add -net $network netmask $mask dev $cbridge");
	if ($?) {
	    return -1;
	}
    }
    return 0;
}

#
# This is where new interfaces get added to the experimental network.
# For each vnode we need to:
#  - possibly create (or arrange to have created) a bridge device
#  - create config file lines for each interface
#  - arrange for the correct routing
#
sub vnodePreConfigExpNetwork($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $vninfo = $private;
    my $ifconfigs  = $vnconfig->{'ifconfig'};
    my $ldconfigs  = $vnconfig->{'ldconfig'};
    my $tunconfigs = $vnconfig->{'tunconfig'};
    my $ifbs;

    # Keep track of links (and implicitly, bridges) that need to be created
    my @links = ();

    # Build up a config file line for all interfaces, starting with cnet
    my $vifstr = "vif = ['" .
	"mac=" . $vninfo->{'cnet'}->{'mac'} . ", " .
	# This tells vif-bridge to use antispoofing iptable rules.
	"ip=" . $vninfo->{'cnet'}->{'ip'} . ", " .
        "bridge=" . $vninfo->{'cnet'}->{'bridge'} . ", " .
        "script=" . $vninfo->{'cnet'}->{'script'} . "'";

    #
    # Grab all of the IFBs we need. 
    #
    if (@$ldconfigs) {
	$ifbs = AllocateIFBs($vmid, $ldconfigs, $private);
	if (! defined($ifbs)) {
	    return -1;
	}
    }

    foreach my $interface (@$ifconfigs){
        print "interface " . Dumper($interface) . "\n"
	    if ($debug > 1);
        my $mac = "";
        my $physical_mac = "";
	my $physical_dev;
        my $tag = 0;
	my $ifname = "veth.${vmid}." . $interface->{'ID'};
	
	#
	# In the era of shared nodes, we cannot name the bridges
	# using experiment local names (e.g., the link name).
	# Bridges are now named after either the physical interface
	# they are associated with or the "tag" if there is no physical
	# interface.
	#
        my $brname;

	if ($interface->{'ITYPE'} eq "loop") {
	    #
	    # No physical device. Its a loopback (trivial) link/lan
	    # All we need is a common bridge to put the veth ifaces into.
	    #
	    $brname = "br" . $interface->{'VTAG'};
            $mac = $interface->{'MAC'};
	}
	elsif ($interface->{'ITYPE'} eq "veth"){
	    #
	    # We will never see a veth on a shared node, thus they
	    # have already been created during the physnode config.
	    #
            $mac = $interface->{'MAC'};
            if ($interface->{'PMAC'} ne "none"){
                $physical_mac = $interface->{'PMAC'};
		$brname = "br" . findIface($interface->{'PMAC'});
            }
	    else {
		$brname = "br" . $interface->{'VTAG'};
	    }
        }
	elsif ($interface->{'ITYPE'} eq "vlan"){
	    my $iface = $interface->{'IFACE'};
	    my $vtag  = $interface->{'VTAG'};
	    #
	    # On a shared node, these interfaces might not exist. This will
	    # happen when the bridges are created, for lack of a better
	    # place. 
	    #
            $mac = $interface->{'MAC'};
            $tag = $interface->{'VTAG'};
            $physical_mac = $interface->{'PMAC'};
	    $physical_dev = "${iface}.${vtag}";
	    $brname = "br" . $physical_dev;
	}
	else {
            $mac = $interface->{'MAC'};
	    $brname = "pbr" . findIface($interface->{'MAC'});
        }

	#
	# If there is shaping info associated with the interface
	# then we need a custom script. We also need an IFB for
	# ingress shaping.
	#
	my $script = "";
	foreach my $ldinfo (@$ldconfigs) {
	    if ($ldinfo->{'IFACE'} eq $mac) {
		$script = "$VMDIR/$vnode_id/enet-$mac";
		my $sh  = "${script}.sh";
		my $log = "${script}.log";
		my $tag = "$vnode_id:" . $ldinfo->{'LINKNAME'};
		my $ifb = pop(@$ifbs);

		createExpNetworkScript($vmid, $interface,
				       $ldinfo, "ifb$ifb", $script, $sh, $log);
	    }
	}

	# add interface to config file line
	$vifstr .= ", 'vifname=$ifname, mac=" .
	    fixupMac($mac) . ", bridge=$brname";
	if ($script ne "") {
	    $vifstr .= ", script=$script";
	}
	$vifstr .= "'";

	# Push vif info
        my $link = {'mac' => fixupMac($mac),
		    'ifname' => $ifname,
                    'brname' => $brname,
		    'script' => $script,
                    'physical_mac' => $physical_mac,
                    'physical_dev' => $physical_dev,
                    'tag' => $tag,
		    'itype' => $interface->{'ITYPE'},
                    };
        push @links, $link;
    }

    #
    # Tunnels
    #
    if (values(%{ $tunconfigs })) {
	#
	# gres and route tables are a global resource.
	#
	if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	    print STDERR "Could not get the global lock after a long time!\n";
	    return -1;
	}
	my %key2gre = ();
	my $maxgre  = 0;
	
	foreach my $tunnel (values(%{ $tunconfigs })) {
	    my $style = $tunnel->{"tunnel_style"};

	    next
		if (! ($style eq "egre"));

	    my $name     = $tunnel->{"tunnel_lan"};
	    my $srchost  = $tunnel->{"tunnel_srcip"};
	    my $dsthost  = $tunnel->{"tunnel_dstip"};
	    my $inetip   = $tunnel->{"tunnel_ip"};
	    my $peerip   = $tunnel->{"tunnel_peerip"};
	    my $mask     = $tunnel->{"tunnel_ipmask"};
	    my $unit     = $tunnel->{"tunnel_unit"};
	    my $grekey   = $tunnel->{"tunnel_tag"};
	    my $mac      = undef;

	    if (exists($tunnel->{"tunnel_mac"})) {
		$mac = $tunnel->{"tunnel_mac"};
	    }
	    else {
		$mac = GenFakeMac();
	    }

	    #
	    # Need to create an openvswitch bridge and gre tunnel inside.
	    # We can then put the veth device into the bridge. 
	    #
	    # These are the devices outside the container. 
	    my $veth = "greth.${vmid}.${unit}";
	    my $gre  = "gre$vmid.$unit";
	    my $br   = "br$vmid.$unit";
	    if (! -d "/sys/class/net/$br/bridge") {
		mysystem2("$OVSCTL add-br $br");
		if ($?) {
		    TBScriptUnlock();
		    return -1;
		}
		# Record tunnel bridge created. 
		$private->{'tunnelbridges'}->{$br} = $br;

		mysystem2("$OVSCTL add-port $br $gre -- set interface $gre ".
			  "  type=gre options:remote_ip=$dsthost " .
			  "           options:local_ip=$srchost " .
			  (1 ? "      options:key=$grekey" : ""));
		if ($?) {
		    TBScriptUnlock();
		    return -1;
		}
	    }

	    #
	    # Create a wrapper script. All work handled in emulab-tun.pl
	    #
	    my ($imac,$omac) = build_fake_macs($mac);
	    my $script = "$VMDIR/$vnode_id/tun-$name";
	    $imac = fixupMac($imac);
	    $omac = fixupMac($omac);

	    if (createTunnelScript($vmid, $script, $omac, $br)) {
		print STDERR "Could not create tunnel script for $name\n";
		TBScriptUnlock();
		return -1;
	    }

	    # add interface to config file line
	    $vifstr .= ", 'vifname=$veth, mac=$imac, script=$script'";
	}
	TBScriptUnlock();
    }

    # push out config file line for all interfaces
    # XXX note that we overwrite since a modify might add/sub IFs
    $vifstr .= "]";
    addConfig($vninfo, $vifstr, 1);

    $vninfo->{'links'} = \@links;
    return 0;
}

sub vnodeConfigResources($$$$){
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $attributes = $vnconfig->{'attributes'};
    my $memory;

    #
    # Give the vnode some memory. The server usually tells us how much. 
    #
    if (exists($attributes->{'VM_MEMSIZE'})) {
	# Better be MB.
	$memory = $attributes->{'VM_MEMSIZE'};
    }
    else  {
	$memory = 128;
    }
    addConfig($private, "memory = $memory", 1);
    return 0;
}

sub vnodeConfigDevices($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    return 0;
}

sub vnodeState($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    my $err = 0;
    my $out = VNODE_STATUS_UNKNOWN();

    # right now, if it shows up in the list, consider it running
    if (domainExists($vnode_id)) {
	$out = VNODE_STATUS_RUNNING();
    }
    # otherwise, if the logical (root) disk exists, consider it stopped
    elsif (exists($private->{'disks'}->{$vnode_id}) &&
	   findLVMLogicalVolume($private->{'disks'}->{$vnode_id})) {
	$out = VNODE_STATUS_STOPPED();
    }
    return ($err, $out);
}

sub vnodeBoot($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $vninfo = $private;

    if (!exists($vninfo->{'cffile'})) {
	die("libvnode_xen: vnodeBoot $vnode_id: no essential state!?");
    }

    #
    # We made it here without error, so create persistent state.
    # Xen config file...
    #
    my $config = configFile($vnode_id);
    if ($vninfo->{'cfchanged'}) {
	if (createXenConfig($config, $vninfo->{'cffile'})) {
	    die("libvnode_xen: vnodeBoot $vnode_id: could not create $config");
	}
    } elsif (! -e $config) {
	die("libvnode_xen: vnodeBoot $vnode_id: $config file does not exist!");
    }

    # DHCP entry...
    if (exists($vninfo->{'dhcp'})) {
	my $name = $vninfo->{'dhcp'}->{'name'};
	my $ip = $vninfo->{'dhcp'}->{'ip'};
	my $mac = $vninfo->{'dhcp'}->{'mac'};
	addDHCP($name, $ip, $mac, 1) == 0
	    or die("libvnode_xen: vnodeBoot $vnode_id: dhcp setup error!");
    }

    # physical bridge devices...
    if (createExpBridges($vmid, $vninfo->{'links'}, $private)) {
	die("libvnode_xen: vnodeBoot $vnode_id: could not create bridges");
    }

    # notify stated that we are about to boot
    libutil::setState("BOOTING");

    # and finally, create the VM
    mysystem("xm create $config");
    print "Created virtual machine $vnode_id\n";
    return 0;
}

sub vnodePostConfig($)
{
    return 0;
}

sub vnodeReboot($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    if ($vmid =~ m/(.*)/){
        $vmid = $1;
    }
    mysystem("/usr/sbin/xm reboot $vmid");
}

sub vnodeTearDown($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    # Lots of shared resources 
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global vz lock after a long time!\n";
	return -1;
    }

    #
    # Unwind anything we did.
    #

    # Delete the tunnel devices.
    if (exists($private->{'tunnels'})) {
	foreach my $iface (keys(%{ $private->{'tunnels'} })) {
	    mysystem2("/sbin/ip tunnel del $iface");
	    goto badbad
		if ($?);
	    delete($private->{'tunnels'}->{$iface});
	}
    }
    # Delete the ip rules.
    if (exists($private->{'iprules'})) {
	foreach my $iface (keys(%{ $private->{'iprules'} })) {
	    mysystem2("$IPBIN rule del iif $iface");
	    goto badbad
		if ($?);
	    delete($private->{'iprules'}->{$iface});
	}
    }
    #
    # Release the route tables.
    #
    ReleaseRouteTables($vmid, $private)
	if (exists($private->{'routetables'}));

  badbad:
    TBScriptUnlock();
    return 0;
}

sub vnodeDestroy($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;
    my $vninfo = $private;

    #
    # vmid might not be set if vnodeCreate did not succeed. But
    # we still come through here to clean things up.
    #
    if ($vnode_id =~ m/(.*)/){
        $vnode_id = $1;
    }
    if (domainExists($vnode_id)) {
	mysystem("/usr/sbin/xm destroy $vnode_id");
	# XXX hang out awhile waiting for domain to disappear
	domainGone($vnode_id, 15);
    }

    # Always do this.
    return -1
	if (vnodeTearDown($vnode_id, $vmid, $vnconfig, $private));

    # DHCP entry...
    if (exists($vninfo->{'dhcp'})) {
	my $mac = $vninfo->{'dhcp'}->{'mac'};
	subDHCP($mac, 1);
    }

    #
    # We do these whether or not the domain existed
    #
    # Note to Mike from Leigh; this should maybe move to TearDown above?
    #
    destroyExpBridges($vmid, $private) == 0
	or return -1;

    #
    # We keep the IMQs until complete destruction. We do this cause we do
    # want to get into a situation where we stopped a container to do
    # something like take a disk snapshot, and then not be able to
    # restart it cause there are no more resources available (as might
    # happen on a shared node).
    #
    ReleaseIFBs($vmid, $private)
	if (exists($private->{'ifbs'}));

    # Destroy the all the disks.
    foreach my $key (keys(%{ $private->{'disks'} })) {
	my $lvname = $private->{'disks'}->{$key};
	
	if (findLVMLogicalVolume($lvname)) {
	    if (mysystem2("lvremove -f $VGNAME/$lvname")) {
		print STDERR "libvnode_xen: could not destroy disk $lvname!\n";
	    }
	    else {
		delete($private->{'disks'}->{$key});
	    }
	}
    }
    return 0;
}

sub vnodeHalt($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    if ($vnode_id =~ m/(.*)/) {
        $vnode_id = $1;
    }
    #
    # This runs async so use -w to wait until actually destroyed!
    # The problem is that sometimes the container will not die
    # and we just sit here waiting forever. So lets set up an alarm
    # so that we give up after a while and just destroy it. This
    # is okay since we are not doing migration, and all other state
    # is retained.
    #
    my $childpid = fork();
    if ($childpid) {
	local $SIG{ALRM} = sub { kill("TERM", $childpid); };
	alarm 45;
	waitpid($childpid, 0);
	my $stat = $?;
	alarm 0;

	#
	# Any failure, do a destroy.
	#
	if ($stat) {
	    print STDERR "xm shutdown returned $stat. Doing a destroy!\n";
	    mysystem("/usr/sbin/xm destroy $vnode_id");
	}
    }
    else {
	#
	# We have blocked most signals in mkvnode, including TERM.
	# Temporarily unblock and set to default so we die. 
	#
	local $SIG{TERM} = 'DEFAULT';
	exec("/usr/sbin/xm shutdown -w $vnode_id");
	exit(1);
    }
    return 0;
}

# XXX implement these!
sub vnodeExec($$$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private, $command) = @_;

    if ($command eq "sleep 100000000") {
	while (1) {
	    my $stat = domainStatus($vnode_id);
	    # shutdown/destroyed
	    if (!$stat) {
		return 0;
	    }
	    # crashed
	    if ($stat =~ /c/) {
		return -1;
	    }
	    sleep(5);
	}
    }
    return -1;
}

sub vnodeUnmount($$$$)
{
    my ($vnode_id, $vmid, $vnconfig, $private) = @_;

    return 0;
}

#
# Local functions
#

sub findRoot()
{
    my $rootfs = `df / | grep /dev/`;
    if ($rootfs =~ /^(\/dev\/\S+)/) {
	my $dev = $1;
	return $dev;
    }
    die "libvnode_xen: cannot determine root filesystem";
}

sub copyRoot($$)
{
    my ($from, $to) = @_;
    my $disk_path = "/mnt/xen/disk";
    my $root_path = "/mnt/xen/root";
    print "Mount root\n";
    mkpath(['/mnt/xen/root']);
    mkpath(['/mnt/xen/disk']);
    mysystem("mount $from $root_path");
    mysystem("mount -o loop $to $disk_path");
    mkpath([map{"$disk_path/$_"} qw(proc sys home tmp)]);
    print "Copying files\n";
    system("cp -a $root_path/* $disk_path");

    # hacks to make things work!
    disk_hacks($disk_path);

    mysystem("umount $root_path");
    mysystem("umount $disk_path");
}

#
# Create the root "disk" (logical volume)
# XXX this is a temp hack til all vnode creations have an explicit image.
#
sub createRootDisk($)
{
    my ($lv) = @_;
    my $lvname = "image+" . $lv;
    my $full_path = lvmVolumePath($lvname);
    my $size = $XEN_LDSIZE;

    #
    # We only want to do this once.
    #
    system("lvcreate -n $lvname -L ${size}G $VGNAME");
    system("echo y | mkfs -t ext3 $full_path");
    mysystem("e2label $full_path /");
    copyRoot(findRoot(), $full_path);
}

#
# Create an extra, empty disk volume. 
#
sub createAuxDisk($$)
{
    my ($lv,$size) = @_;
    my $full_path = lvmVolumePath($lv);

    mysystem2("lvcreate -n $lv -L ${size} $VGNAME");
    if ($?) {
	return -1;
    }
    return 0;
}

#
# Create a logical volume for the image if it doesn't already exist.
#
sub createImageDisk($$$)
{
    my ($image,$vnode_id,$raref) = @_;
    my $tstamp = $raref->{'IMAGEMTIME'};
    my $lvname = "image+" . $image;
    my $lvmpath = lvmVolumePath($lvname);
    my $imagedatepath = "$METAFS/${image}.date";
    my $imagemetapath = "$METAFS/${image}.metadata";
    my $unpack = 0;

    # We are locked by the caller.

    #
    # Do we have the right image file already? No need to download it
    # again if the timestamp matches. Note that we are using the mod
    # time on the lvm volume path for this, which we set below when
    # the image is downloaded.
    #
    if (findLVMLogicalVolume($lvname)) {
	if (-e $imagedatepath) {
	    my (undef,undef,undef,undef,undef,undef,undef,undef,undef,
		$mtime,undef,undef,undef) = stat($imagedatepath);
	    if ("$mtime" eq "$tstamp") {
		#
		# We want to update the access time to indicate a new
		# use of this image, for pruning unused images later.
		#
		utime(time(), $mtime, $imagedatepath);
		print "Found existing disk: $lvmpath.\n";
		return 0;
	    }
	    print "mtime for $lvmpath differ: local $mtime, server $tstamp\n";
	}
	# For the package case.
	if (-e "/mnt/$image/.mounted" && mysystem2("umount /mnt/$image")) {
	    print STDERR "Could not umount /mnt/$image\n";
	    return -1;
	}
	if (GClvm($lvname)) {
	    print STDERR "Could not GC or rename $lvname\n";
	    return -1;
	}
	unlink($imagedatepath)
	    if (-e $imagedatepath);
	unlink($imagemetapath)
	    if (-e $imagemetapath);
    }

    my $size = $XEN_LDSIZE;
    if (mysystem2("lvcreate -n $lvname -L ${size}G $VGNAME")) {
	print STDERR "libvnode_xen: could not create disk for $image\n";
	return -1;
    }
    my $imagepath = $lvmpath;

    #
    # If the version info indicates a packaged container, then we
    # create a filesystem inside the lvm and download the package to
    # it. We tell the download function to untar it, since otherwise
    # we have to make a copy.
    #
    # XXX Using MBRVERS for now, need something else.
    #
    if (exists($raref->{'MBRVERS'}) && $raref->{'MBRVERS'} == 99) {
	goto bad
	    if (! -e "/mnt/$image" && mysystem2("mkdir -p /mnt/$image"));
	goto bad
	    if (-e "/mnt/$image/.mounted" && mysystem2("umount /mnt/$image"));
	mysystem2("mkfs -t ext3 $imagepath");
	goto bad
	    if ($?);
	mysystem2("mount $imagepath /mnt/$image");
	goto bad
	    if ($?);
	mysystem2("touch /mnt/$image/.mounted");
	goto bad
	    if ($?);
	$unpack = 1;
	$imagepath = "$EXTRAFS/${image}.tar.gz";
    }

    # Now we just download the file, then let create do its normal thing
    if (libvnode::downloadImage($imagepath, 1, $vnode_id, $raref)) {
	print STDERR "libvnode_xen: could not download image $image\n";
	return -1;
    }
    if ($unpack) {
	# Now unpack the tar file, then remove it.
	mysystem2("tar zxf $imagepath -C /mnt/$image");
	goto bad
	    if ($?);
	unlink($imagepath);
	# Mark it as a package.
	$raref->{'ISPACKAGE'} = 1;
	goto bad
	    if ($?);
    }
    # reload has finished, file is written... so let's set its mtime
    mysystem2("touch $imagedatepath")
	if (! -e $imagedatepath);
    utime(time(), $tstamp, $imagedatepath);

    #
    # Additional info about the image. Just store the loadinfo data.
    #
    StoreImageMetadata($imagemetapath, $raref);

    #
    # XXX note that we don't declare RELOADDONE here since we haven't
    # actually created the vnode shadow disk yet.  That is the caller's
    # responsibility.
    #
    return 0;
  bad:
    return -1;
}

sub replace_hack($)
{
    my ($q) = @_;
    if ($q =~ m/(.*)/){
        return $1;
    }
    return "";
}

sub disk_hacks($)
{
    my ($path) = @_;
    # erase cache from LABEL to devices
    my @files = <$path/etc/blkid/*>;
    unlink map{&replace_hack($_)} (grep{m/(.*blkid.*)/} @files);

    rmtree(["$path/var/emulab/boot/tmcc"]);

    # Run prepare inside to clean up.
    system("/usr/sbin/chroot $path /usr/local/etc/emulab/prepare -N");

    # don't try to recursively boot vnodes!
    unlink("$path/usr/local/etc/emulab/bootvnodes");

    # don't set up the xen bridge on guests
    system("sed -i.bak -e '/xenbridge-setup/d' $path/etc/network/interfaces");

    # don't start dhcpd in the VM
    unlink("$path/etc/dhcpd.conf");
    unlink("$path/etc/dhcp/dhcpd.conf");

    # No xen daemons
    unlink("$path/etc/init.d/xend");
    unlink("$path/etc/init.d/xendomains");

    # Remove mtab just in case
    unlink("$path/etc/mtab");

    # Remove dhcp client state
    unlink("$path/var/lib/dhcp/dhclient.leases");

    # Clear out the cached control net interface name
    unlink("$path/var/run/cnet");

    # remove swap partitions from fstab
    system("sed -i.bak -e '/swap/d' $path/etc/fstab");

    # remove scratch partitions from fstab
    system("sed -i.bak -e '/scratch/d' $path/etc/fstab");
    system("sed -i.bak -e '${EXTRAFS}/d' $path/etc/fstab");
    system("sed -i.bak -e '${METAFS}/d' $path/etc/fstab");

    # fixup fstab: change UUID=blah to LABEL=/
    system("sed -i.bak -e 's/UUID=[0-9a-f-]*/LABEL=\\//' $path/etc/fstab");

    # enable the correct device for console
    if (-f "$path/etc/inittab") {
	    system("sed -i.bak -e 's/xvc0/console/' $path/etc/inittab");
    }

    if (-f "$path/etc/init/ttyS0.conf") {
	    system("sed -i.bak -e 's/ttyS0/hvc0/' $path/etc/init/ttyS0.conf");
    }
}

sub configFile($)
{
    my ($id) = @_;
    if ($id =~ m/(.*)/){
        return "$VMDIR/$1/xm.conf";
    }
    return "";
}

#
# Return MB of memory used by dom0
# Give it at least 256MB of memory.
#
sub domain0Memory()
{
    my $memtotal = `grep MemTotal /proc/meminfo`;
    if ($memtotal =~ /^MemTotal:\s*(\d+)\s(\w+)/) {
	my $num = $1;
	my $type = $2;
	if ($type eq "kB") {
	    $num /= 1024;
	}
	$num = int($num);
	return ($num >= $MIN_MB_DOM0MEM ? $num : $MIN_MB_DOM0MEM);
    }
    die("Could not find what the total memory for domain 0 is!");
}

#
# Return total MB of memory available to domUs
#
sub totalMemory()
{
    # returns amount in MB
    my $meminfo = `/usr/sbin/xm info | grep total_memory`;
    if ($meminfo =~ m/\s*total_memory\s*:\s*(\d+)/){
        my $mem = int($1);
        return $mem - domain0Memory();
    }
    die("Could not find what the total physical memory on this machine is!");
}

#
# Returns the control net IP of the physical host.
#
sub domain0ControlNet()
{
    #
    # XXX we use a woeful hack to get the virtual control net address,
    # just adding one to the GW address.  With our current hacky vnode IP
    # assignment, this address will always be available.
    #
    my (undef,$vmask,$vgw) = findVirtControlNet();
    if ($vgw =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
	my $vip = "$1.$2.$3." . ($4+1);
	return ($vip, $vmask);
    }
    die("domain0ControlNet: could not create control net virtual IP");
}

#
# Emulab image compatibility: the physical host acts as DHCP server for all
# the hosted vnodes since they expect to find out there identity, and identify
# their control net, via DHCP.
#
sub createDHCP()
{
    my ($all) = @_;
    my ($vnode_net,$vnode_mask,$vnode_gw) = findVirtControlNet();
    my (undef,undef,
	$cnet_mask,undef,$cnet_net,undef,$cnet_gw) = findControlNet();

    my $vnode_dns = findDNS($vnode_gw);
    my $domain    = findDomain();
    my $file;

    if (-d "/etc/dhcp") {
	$file = $NEW_DHCPCONF_FILE;
    } else {
	$file = $DHCPCONF_FILE;
    }
    open(FILE, ">$file") or die("Cannot write $file");

    print FILE <<EOF;
#
# Do not edit!  Auto-generated by libvnode_xen.pm.
#
ddns-update-style  none;
default-lease-time 604800;
max-lease-time     704800;

shared-network xen {
subnet $vnode_net netmask $vnode_mask {
    option domain-name-servers $vnode_dns;
    option domain-name "$domain";
    option routers $vnode_gw;

    # INSERT VNODES AFTER

    # INSERT VNODES BEFORE
}

subnet $cnet_net netmask $cnet_mask {
    option domain-name-servers $vnode_dns;
    option domain-name "$domain";
    option routers $cnet_gw;

    # INSERT VNODES AFTER

    # INSERT VNODES BEFORE
}
}

EOF
    ;
    close(FILE);

    restartDHCP();
}

#
# Add or remove (host,IP,MAC) in the local dhcpd.conf
# If an entry already exists, replace it.
#
# XXX assume one line per entry
#
sub addDHCP($$$$) { return modDHCP(@_, 0); }
sub subDHCP($$) { return modDHCP("--", "--", @_, 1); }

sub modDHCP($$$$$)
{
    my ($host,$ip,$mac,$doHUP,$dorm) = @_;
    my $dhcp_config_file = $DHCPCONF_FILE;
    if (-f $NEW_DHCPCONF_FILE) {
        $dhcp_config_file = $NEW_DHCPCONF_FILE;
    }
    my $cur = "$dhcp_config_file";
    my $bak = "$dhcp_config_file.old";
    my $tmp = "$dhcp_config_file.new";

    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 900) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }

    if (!open(NEW, ">$tmp")) {
	print STDERR "Could not create new DHCP file, ",
		     "$host/$ip/$mac not added\n";
	TBScriptUnlock();
	return -1;
    }
    if (!open(OLD, "<$cur")) {
	print STDERR "Could not open $cur, ",
		     "$host/$ip/$mac not added\n";
	close(NEW);
	unlink($tmp);
	TBScriptUnlock();
	return -1;
    }
    my $changed = 0;
    $mac = lc($mac);
    if ($dorm) {
	while (my $line = <OLD>) {
	    if ($line =~ /ethernet ([\da-f:]+); fixed-address/i) {
		my $omac = lc($1);
		if ($mac eq $omac) {
		    # skip this entry.
		    $changed = 1;
		    next;
		}
	    }
	    print NEW $line;
	}
	goto done;
    }
    $host = lc($host);
    my $insubnet = 0;
    my $inrange = 0;
    my $found = 0;
    while (my $line = <OLD>) {
	if ($found) {
	    ;
	} elsif ($line =~ /^subnet\s*([\d\.]+)\s*netmask\s*([\d\.]+)/) {
	    my $subnet  = $1;
	    my $submask = $2;

	    #
	    # Is the IP we need to add, within this subnet?
	    #
	    $insubnet = 1
		if (inet_ntoa(inet_aton($ip) &
			      inet_aton($submask)) eq $subnet);
	} elsif ($insubnet && $line =~ /INSERT VNODES AFTER/) {
	    $inrange = 1;
	} elsif ($insubnet && $line =~ /INSERT VNODES BEFORE/) {
	    $inrange = 0;
	    $found = 1;
	    if (!$dorm) {
		print NEW formatDHCP($host, $ip, $mac), "\n";
		$changed = 1;
	    }
	} elsif ($inrange &&
		 ($line =~ /ethernet ([\da-f:]+); fixed-address ([\d\.]+); option host-name ([^;]+);/i)) {
	    my $ohost = lc($3);
	    my $oip = $2;
	    my $omac = lc($1);
	    if ($mac eq $omac) {
		if ($dorm) {
		    # skip this entry; don't mark found so we find all
		    $changed = 1;
		    next;
		}
		$found = 1;
		if ($host ne $ohost || $ip ne $oip) {
		    print NEW formatDHCP($host, $ip, $omac), "\n";
		    $changed = 1;
		    next;
		}
	    }
	}
	print NEW $line;
    }
  done:
    close(OLD);
    close(NEW);

    #
    # Nothing changed, we are done.
    #
    if (!$changed) {
	unlink($tmp);
	TBScriptUnlock();
	return 0;
    }

    #
    # Move the new file in place, and optionally restart dhcpd
    #
    if (-e $bak) {
	if (!unlink($bak)) {
	    print STDERR "Could not remove $bak, ",
			 "$host/$ip/$mac not added\n";
	    unlink($tmp);
	    TBScriptUnlock();
	    return -1;
	}
    }
    if (!rename($cur, $bak)) {
	print STDERR "Could not rename $cur -> $bak, ",
		     "$host/$ip/$mac not added\n";
	unlink($tmp);
	TBScriptUnlock();
	return -1;
    }
    if (!rename($tmp, $cur)) {
	print STDERR "Could not rename $tmp -> $cur, ",
		     "$host/$ip/$mac not added\n";
	rename($bak, $cur);
	unlink($tmp);
	TBScriptUnlock();
	return -1;
    }

    if ($doHUP) {
        restartDHCP();
    }

    TBScriptUnlock();
    return 0;
}

sub restartDHCP()
{
    my $dhcpd_service = 'dhcpd';
    if (-f '/etc/init/isc-dhcp-server.conf') {
        $dhcpd_service = 'isc-dhcp-server';
    }

    # make sure dhcpd is running
    if (-x '/sbin/initctl') {
        # Upstart
        if (mysystem2("/sbin/initctl restart $dhcpd_service") != 0) {
            mysystem2("/sbin/initctl start $dhcpd_service");
        }
    } else {
        #sysvinit
        mysystem2("/etc/init.d/$dhcpd_service restart");
    }
}

sub formatDHCP($$$)
{
    my ($host,$ip,$mac) = @_;
    my $xip = $ip;
    $xip =~ s/\.//g;

    return ("    host xen$xip { ".
	    "hardware ethernet $mac; ".
	    "fixed-address $ip; ".
	    "option host-name $host; }");
}

# convert 123456 into 12:34:56
sub fixupMac($)
{
    my ($x) = @_;
    $x =~ s/(\w\w)/$1:/g;
    chop($x);
    return $x;
}

#
# Write out the script that will be called when the control-net interface
# is instantiated by Xen.  This is just a stub which calls the common
# Emulab script in /etc/xen/scripts.
#
# XXX can we get rid of this stub by using environment variables?
#
sub createControlNetworkScript($$$)
{
    my ($vmid,$data,$file) = @_;
    my $host_ip = $data->{'hip'};
    my $name = $data->{'name'};
    my $ip = $data->{'ip'};

    open(FILE, ">$file") or die $!;
    print FILE "#!/bin/sh\n";
    print FILE "/bin/mv -f ${file}.debug ${file}.debug.old\n";
    print FILE "/etc/xen/scripts/emulab-cnet.pl $vmid $host_ip $name $ip \$* ".
	">${file}.debug 2>&1\n";
    print FILE "exit \$?\n";
    close(FILE);
    chmod(0555, $file);
}

#
# Write out the script that will be called when a tunnel interface
# is instantiated by Xen.  This is just a stub which calls the common
# Emulab script in /etc/xen/scripts.
#
# XXX can we get rid of this stub by using environment variables?
#
sub createTunnelScript($$$$)
{
    my ($vmid, $file, $mac, $vbr) = @_;

    open(FILE, ">$file")
	or return -1;
    
    print FILE "#!/bin/sh\n";
    print FILE "/bin/mv -f ${file}.debug ${file}.debug.old\n";
    print FILE "/etc/xen/scripts/emulab-tun.pl ".
	"$vmid $mac $vbr \$* >${file}.debug 2>&1\n";
    print FILE "exit \$?\n";
    close(FILE);
    chmod(0555, $file);
    return 0;
}

sub createExpNetworkScript($$$$$$$)
{
    my ($vmid,$ifc,$info,$ifb,$wrapper,$file,$lfile) = @_;
    my $TC = "/sbin/tc";

    if (! open(FILE, ">$wrapper")) {
	print STDERR "Error creating $wrapper: $!\n";
	return -1;
    }
    print FILE "#!/bin/sh\n";
    print FILE "/bin/mv -f ${lfile} ${lfile}.old\n";
    print FILE "echo \"\$*\" >$lfile\n";
    print FILE "echo \"\$vif\" >>$lfile\n";
    print FILE "echo \"\$XENBUS_PATH\" >>$lfile\n";
    print FILE "sh $file \$* >>$lfile 2>&1\n";
    print FILE "exit \$?\n";
    close(FILE);
    chmod(0554, $wrapper);
    
    if (! open(FILE, ">$file")) {
	print STDERR "Error creating $file: $!\n";
	return -1;
    }
    print FILE "#!/bin/sh\n";
    print FILE "OP=\$1\n";
    print FILE "/etc/xen/scripts/vif-bridge \$*\n";
    print FILE "STAT=\$?\n";
    print FILE "if [ \$STAT -ne 0 -o \"\$OP\" != \"online\" ]; then\n";
    print FILE "    exit \$STAT\n";
    print FILE "fi\n";
    print FILE "# XXX redo what vif-bridge does to get named interface\n";
    print FILE "vifname=`xenstore-read \$XENBUS_PATH/vifname`\n";
    print FILE "echo \"Configuring shaping for \$vifname (MAC ",
                     $info->{'IFACE'}, ")\"\n";

    my $iface     = $info->{'IFACE'};
    my $type      = $info->{'TYPE'};
    my $linkname  = $info->{'LINKNAME'};
    my $vnode     = $info->{'VNODE'};
    my $inet      = $info->{'INET'};
    my $mask      = $info->{'MASK'};
    my $pipeno    = $info->{'PIPE'};
    my $delay     = $info->{'DELAY'};
    my $bandw     = $info->{'BW'};
    my $plr       = $info->{'PLR'};
    my $rpipeno   = $info->{'RPIPE'};
    my $rdelay    = $info->{'RDELAY'};
    my $rbandw    = $info->{'RBW'};
    my $rplr      = $info->{'RPLR'};
    my $red       = $info->{'RED'};
    my $limit     = $info->{'LIMIT'};
    my $maxthresh = $info->{'MAXTHRESH'};
    my $minthresh = $info->{'MINTHRESH'};
    my $weight    = $info->{'WEIGHT'};
    my $linterm   = $info->{'LINTERM'};
    my $qinbytes  = $info->{'QINBYTES'};
    my $bytes     = $info->{'BYTES'};
    my $meanpsize = $info->{'MEANPSIZE'};
    my $wait      = $info->{'WAIT'};
    my $setbit    = $info->{'SETBIT'};
    my $droptail  = $info->{'DROPTAIL'};
    my $gentle    = $info->{'GENTLE'};

    $delay  = int($delay + 0.5) * 1000;
    $rdelay = int($rdelay + 0.5) * 1000;

    $bandw *= 1000;
    $rbandw *= 1000;

    my $queue = "";
    if ($qinbytes) {
	if ($limit <= 0 || $limit > (1024 * 1024)) {
	    print "Q limit $limit for pipe $pipeno is bogus, using default\n";
	}
	else {
	    $queue = int($limit/1500);
	    $queue = $queue > 0 ? $queue : 1;
	}
    }
    elsif ($limit != 0) {
	if ($limit < 0 || $limit > 100) {
	    print "Q limit $limit for pipe $pipeno is bogus, using default\n";
	}
	else {
	    $queue = $limit;
	}
    }

    my $pipe10 = $pipeno + 10;
    my $pipe20 = $pipeno + 20;
    $iface = "\$vifname";
    my $cmd;
    if ($queue ne "") {
	$cmd = "/sbin/ifconfig $iface txqueuelen $queue";
	print FILE "echo \"$cmd\"\n";
	print FILE "$cmd\n\n";
    }
    my @cmds = ();

    if ($xeninfo{xen_major} >= 4) {
	push(@cmds,
	     "$TC qdisc add dev $iface handle $pipe20 root htb default 1");
	if ($bandw != 0) {
	    push(@cmds,
		 "$TC class add dev $iface classid $pipe20:1 ".
		 "parent $pipe20 htb rate ${bandw} ceil ${bandw}");
	}
	push(@cmds,
	     "$TC qdisc add dev $iface handle $pipe10 parent $pipe20:1 ".
	     "netem drop $plr delay ${delay}us");

	#
	# Incoming traffic shaping.
	#
	if ($type ne "duplex") {
	    $rbandw = $bandw;
	}
 	push(@cmds, "$IFCONFIG $ifb up");
	push(@cmds, "$TC qdisc del dev $ifb root");
	push(@cmds, "$TC qdisc add dev $iface handle ffff: ingress");
	push(@cmds, "$TC filter add dev $iface parent ffff: protocol ip ".
	     "u32 match u32 0 0 action mirred egress redirect dev $ifb");
 	push(@cmds, "$TC qdisc add dev $ifb root handle 2: htb default 1");
	push(@cmds, "$TC class add dev $ifb parent 2: classid 2:1 ".
	     "htb rate ${rbandw} ceil ${rbandw}");

	if ($type eq "duplex") {
	    push(@cmds,
		 "$TC qdisc add dev $ifb handle 2:2 parent 2:1 ".
		 "netem drop $rplr delay ${rdelay}us");
	}
    }
    else {
	push(@cmds,
	     "$TC qdisc add dev $iface handle $pipeno root plr $plr");
	push(@cmds,
	     "$TC qdisc add dev $iface handle $pipe10 ".
	     "parent ${pipeno}:1 delay usecs $delay");
	push(@cmds,
	     "$TC qdisc add dev $iface handle $pipe20 ".
	     "parent ${pipe10}:1 htb default 1");
	if ($bandw != 0) {
	    push(@cmds,
		 "$TC class add dev $iface classid $pipe20:1 ".
		 "parent $pipe20 htb rate ${bandw} ceil ${bandw}");
	}
    }
    foreach my $cmd (@cmds) {
	print FILE "echo \"$cmd\"\n";
	print FILE "$cmd\n\n";
    }
    print FILE "exit 0\n";

    close(FILE);
    chmod(0554, $file);
    return 0;
}

sub createExpBridges($$$)
{
    my ($vmid,$linfo,$private) = @_;

    if (@$linfo == 0) {
	return 0;
    }

    #
    # Since bridges and physical interfaces can be shared between vnodes,
    # we need to serialize this.
    #
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 1800) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }

    # read the current state of affairs
    makeIfaceMaps();
    makeBridgeMaps();

    foreach my $link (@$linfo) {
	my $mac = $link->{'mac'};
	my $pmac = $link->{'physical_mac'};
	my $brname = $link->{'brname'};
	my $tag = $link->{'tag'};

	print "$vmid: looking up bridge $brname ".
	    "(mac=$mac, pmac=$pmac, tag=$tag)\n"
		if ($debug);

	#
	# Sanity checks (all fatal errors if incorrect right now):
	# Virtual interface should not exist at this point,
	# Any physical interfaces should exist,
	# If physical interface is in a bridge, it must be the right one,
	#
	my $vdev = findIface($mac);
	if ($vdev) {
	    print STDERR "createExpBridges: $vdev ($mac) should not exist!\n";
	    goto bad;
	}
	my $pdev;
	my $pbridge;
	if ($pmac ne "") {
	    #
	    # Look for vlan devices that need to be created.
	    #
	    if ($link->{'itype'} eq "vlan") {
		$pdev = $link->{'physical_dev'};
		my $iface = findIface($pmac);

		if (! -d "/sys/class/net/$pdev") {
		    mysystem2("$VLANCONFIG set_name_type DEV_PLUS_VID_NO_PAD");
		    mysystem2("$VLANCONFIG add $iface $tag");
		    goto bad
			if ($?);
		    mysystem2("$VLANCONFIG set_name_type VLAN_PLUS_VID_NO_PAD");

		    #
		    # We do not want the vlan device to have the same
		    # mac as the physical device, since that will confuse
		    # findif later.
		    #
		    my $bmac = fixupMac(GenFakeMac());
		    mysystem2("$IPBIN link set $pdev address $bmac");
		    goto bad
			if ($?);
		    
		    mysystem2("$IFCONFIG $pdev up");
		    mysystem2("$ETHTOOL -K $pdev tso off gso off");
		    makeIfaceMaps();

		    # Another thing that seems to screw up, causing the ciscos
		    # to drop packets with an undersize error.
		    mysystem2("$ETHTOOL -K $iface txvlan off");
		}
	    }
	    else {
		$pdev = findIface($pmac);
	    }
	    if (!$pdev) {
		print STDERR "createExpBridges: $pdev ($pmac) should exist!\n";
		goto bad;
	    }
	    $pbridge = findBridge($pdev);
	    if ($pbridge && $pbridge ne $brname) {
		print STDERR "createExpBridges: ".
		    "$pdev ($pmac) in wrong bridge $pbridge!\n";
		goto bad;
	    }
	}

	# Create bridge if it does not exist
	if (!existsBridge($brname)) {
	    if (mysystem2("$BRCTL addbr $brname")) {
		print STDERR "createExpBridges: could not create $brname\n";
		goto bad;
	    }
	    #
	    # Bad feature of bridges; they take on the lowest numbered
	    # mac of the added interfaces (and it changes as interfaces
	    # are added and removed!). But the main point is that we end
	    # up with a bridge that has the same mac as a physical device
	    # and that screws up findIface(). But if we "assign" a mac
	    # address, it does not change and we know it will be unique.
	    #
	    my $bmac = fixupMac(GenFakeMac());
	    mysystem2("$IPBIN link set $brname address $bmac");
	    goto bad
		if ($?);
	    
	    if (mysystem2("$IFCONFIG $brname up")) {
		print STDERR "createExpBridges: could not ifconfig $brname\n";
		goto bad;
	    }
	}
	# record bridge in use.
	$private->{'physbridges'}->{$brname} = $brname;

	# Add physical device to bridge if not there already
	if ($pdev && !$pbridge) {
	    if (mysystem2("$BRCTL addif $brname $pdev")) {
		print STDERR
		    "createExpBridges: could not add $pdev to $brname\n";
		goto bad;
	    }
	}
    }
    TBScriptUnlock();
    return 0;
  bad:
    TBScriptUnlock();
    return -1;
}

sub destroyExpBridges($$)
{
    my ($vmid,$private) = @_;

    # Delete bridges we created which we know have no members.
    if (exists($private->{'tunnelbridges'})) {
	foreach my $brname (keys(%{ $private->{'tunnelbridges'} })) {
	    mysystem2("$IFCONFIG $brname down");	    
	    mysystem2("$OVSCTL del-br $brname");
	    delete($private->{'tunnelbridges'}->{$brname});
	}
    }

    #
    # In general, bridges can be shared between containers and they
    # can change while not under the lock, since vnodeboot is called
    # without the lock, and the bridges are populated by create.
    # On a non-shared node, this is not really an issue since things
    # do not change that often. On a shared node we could actually
    # get bit by this race, which is too bad, cause on a shared node
    # we could get LOTS of bridges left behind. Not sure what to
    # do about this yet, so lets not reclaim anything at the moment,
    # and I will ponder things more.
    #
    return 0
	if (1);
    
    #
    # Since bridges and physical interfaces can be shared between vnodes,
    # we need to serialize this.
    #
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 1800) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }

    if (exists($private->{'physbridges'})) {
	makeBridgeMaps();
	
	foreach my $brname (keys(%{ $private->{'physbridges'} })) {
	    my @ifaces = findBridgeIfaces($brname);
	    if (@ifaces <= 1) {
		delbr($brname);
		delete($private->{'physbridges'}->{$brname})
		    if (! $?);
	    }
	}
    }
    TBScriptUnlock();
    return 0;
}

sub domainStatus($)
{
    my ($id) = @_;

    my $status = `xm list --long $id 2>/dev/null`;
    if ($status =~ /\(state ([\w-]+)\)/) {
	return $1;
    }
    return "";
}

sub domainExists($)
{
    my ($id) = @_;    
    return (domainStatus($id) ne "");
}

sub domainGone($$)
{
    my ($id,$wait) = @_;

    while ($wait--) {
	if (!domainExists($id)) {
	    return 1;
	}
	sleep(1);
    }
    return 0;
}

#
# Add a line 'str' to the XenConfig array for vnode 'vmid'.
#
# If overwrite is set, any existing line with the same key is overwritten,
# otherwise it is ignored.  If the line doesn't exist, it is always added.
#
# XXX overwrite is a hack.  Without a full parse of the config file lines
# we cannot say that two records are "the same" in particular because some
# records contains info for multiple instances (e.g., "vif").  In those
# cases, we would need to partially overwrite lines.  But we don't,
# we just overwrite the entire line.
#
sub addConfig($$$)
{
    my ($vninfo,$str,$overwrite) = @_;
    my $vmid = $vninfo->{'vmid'};

    if (!exists($vninfo->{'cffile'})) {
	die("libvnode_xen: addConfig: no state for vnode $vmid!?");
    }
    my $aref = $vninfo->{'cffile'};

    #
    # If appending (overwrite==2) or new line is a comment, tack it on.
    #
    if ($overwrite == 2 || $str =~ /^\s*#/) {
	push(@$aref, $str);
	return;
    }

    #
    # Other lines should be of the form key=value.
    # XXX if they are not, we just append them right now.
    #
    my ($key,$val);
    if ($str =~ /^\s*([^=\s]+)\s*=\s*(.*)$/) {
	$key = $1;
	$val = $2;
    } else {
	push(@$aref, $str);
	return;
    }

    #
    # For key=value lines, look for existing instance, replacing as required.
    #
    my $found = 0;
    for (my $i = 0; $i < scalar(@$aref); $i++) {
	if ($aref->[$i] =~ /^\s*#/) {
	    next;
	}
	if ($aref->[$i] =~ /^\s*([^=\s]+)\s*=\s*(.*)$/) {
	    my $ckey = $1;
	    my $cval = $2;
	    if ($ckey eq $key) {
		if ($overwrite && $cval ne $val) {
		    $aref->[$i] = $str;
		    $vninfo->{'cfchanged'} = 1;
		}
		return;
	    }
	}
    }

    #
    # Not found, add it to the end
    #
    push(@$aref, $str);
    $vninfo->{'cfchanged'} = 1;
}

sub readXenConfig($)
{
    my ($config) = @_;
    my @cflines = ();

    if (!open(CF, "<$config")) {
	return undef;
    }
    while (<CF>) {
	chomp;
	push(@cflines, "$_");
    }
    close(CF);

    return \@cflines;
}

sub createXenConfig($$)
{
    my ($config,$lines) = @_;

    mkpath([dirname($config)]);
    if (!open(CF, ">$config")) {
	print STDERR "libvnode_xen: could not create $config\n";
	return -1;
    }
    foreach (@$lines) {
	print CF "$_\n";
    }

    close(CF);
    return 0;
}

sub lookupXenConfig($$)
{
    my ($aref, $key) = @_;

    #
    # Look for key=value.
    #
    for (my $i = 0; $i < scalar(@$aref); $i++) {
	if ($aref->[$i] =~ /^\s*#/) {
	    next;
	}
	if ($aref->[$i] =~ /^\s*([^=\s]+)\s*=\s*(.*)$/) {
	    my $ckey = $1;
	    my $cval = $2;
	    if ($ckey eq $key) {
		return $cval;
	    }
	}
    }
    return undef;
}

sub parseXenDiskInfo($$)
{
    my ($vnode_id, $aref) = @_;
    my $disks = {};

    #
    # Find the disk info and process the stanzas.
    #
    my $stanzas = lookupXenConfig($aref, "disk");
    if (!defined($stanzas)) {
	# No way to clean up from this. Gack.
	print STDERR "xen_vnodeCreate: Cannot find disk stanza in config\n";
	return undef
    }
    my $disklist = eval $stanzas;
    foreach my $disk (@$disklist) {
	if ($disk =~ /^phy:([^,]*),([^,]*)/) {
	    my $device = $1;
	    my $vndisk = $2;
	    # Need to pull out the lvm name from the device path.
	    my $lvname = basename($device);
		
	    # The root disk is marked by sda or xvda.
	    if ($2 eq "sda" || $2 eq "xvda") {
		$disks->{$vnode_id} = $lvname;
	    }
	    else {
		$disks->{$lvname} = $lvname;
	    }
	}
	else {
	    print STDERR "Cannot parse disk: $disk\n";
	    return undef;
	}
    }
    return $disks;
}

#
# Mike's replacements for Jon's Xen python-class-using code.
#
# Nothing personal, just that code used an external shell script which used
# an external python class which used an LVM shared library which comes from
# who knows where--all of which made me nervous.
#

#
# Return size of volume group in (decimal, aka disk-manufactuer) GB.
#
sub lvmVGSize($)
{
    my ($vg) = @_;

    my $size = `vgs --noheadings -o size $vg`;
    if ($size =~ /(\d+\.\d+)([mgt])/i) {
	$size = $1;
	my $u = lc($2);
	if ($u eq "m") {
	    $size /= 1000;
	} elsif ($u eq "t") {
	    $size *= 1000;
	}
	return $size;
    }
    die "libvnode_xen: cannot parse LVM volume group size";
}

sub lvmVolumePath($)
{
    my ($name) = @_;
    return "/dev/$VGNAME/$name";
}

sub findLVMLogicalVolume($)
{
    my ($lvm)  = @_;
    my $lvpath = lvmVolumePath($lvm);
    my $exists = `lvs --noheadings -o origin $lvpath > /dev/null 2>&1`;
    return 0
	if ($?);

    return 1;
}

#
# Return the LVM that the indicated one is a snapshot of, or a null
# string if none.
#
sub findLVMOrigin($)
{
    my ($lv) = @_;

    foreach (`lvs --noheadings -o name,origin $VGNAME`) {
	if (/^\s*${lv}\s+(\S+)\s*$/) {
	    return $1;	
	}
    }
    return "";
}

#
# Rename or GC an image lvm. We can collect the lvm if there are no
# other lvms based on it.
#
sub GClvm($)
{
    my ($image)  = @_;
    my $oldest   = 0;
    my $inuse    = 0;
    my $found    = 0;

    if (! open(LVS, "lvs --noheadings -o lv_name,origin $VGNAME |")) {
	print STDERR "Could not start lvs\n";
	return -1;
    }
    while (<LVS>) {
	my $line = $_;
	my $imname;
	my $origin;
	
	if ($line =~ /^\s*([-\w\.\+]+)\s*$/) {
	    $imname = $1;
	}
	elsif ($line =~ /^\s*([-\w\.\+]+)\s+([-\w\.]+)$/) {
	    $imname = $1;
	    $origin = $2;
	}
	else {
	    print STDERR "Unknown line from lvs: $line\n";
	    return -1;
	}
	#print "$imname";
	#print " : $origin" if (defined($origin));
	#print "\n";

	# The exact image we are trying to GC.
	$found = 1
	    if ($imname eq $image);

	# If the origin is the image we are looking for,
	# then we mark it as inuse.
	$inuse = 1
	    if (defined($origin) && $origin eq $image);

	# We want to find the highest numbered backup for this image.
	# Might not be any of course.
	if ($imname =~ /^([-\w]+)\.(\d+)$/) {
	    $oldest = $2
		if ($1 eq $image && $2 > $oldest);
	}
    }
    close(LVS);
    return -1
	if ($?);
    print "found:$found, inuse:$inuse, oldest:$oldest\n";
    if (!$found) {
	print STDERR "GClvm($image): no such lvm found\n";
	return -1;
    }
    if (!$inuse) {
	print "GClvm($image): not in use; deleting\n";
 	mysystem2("lvremove -f /dev/$VGNAME/$image");
	return -1
	    if ($?);
	return 0;
    }
    $oldest++;
    # rename nicely works even when snapshots exist
    mysystem2("lvrename /dev/$VGNAME/$image /dev/$VGNAME/$image.$oldest");
    return -1
	if ($?);
    
    return 0;
}

#
# Deal with IFBs.
#
#
# Deal with IFBs.
#
sub AllocateIFBs($$$)
{
    my ($vmid, $node_lds, $private) = @_;
    my @ifbs = ();

    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 1800) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }

    my %MDB;
    if (!dbmopen(%MDB, $IFBDB, 0660)) {
	print STDERR "*** Could not create $IFBDB\n";
	TBScriptUnlock();
	return undef;
    }

    #
    # We need an IFB for every ld, so just make sure we can get that many.
    #
    my $needed = scalar(@$node_lds);

    #
    # First pass, look for enough before actually allocating them.
    #
    my $i = 0;
    my $n = $needed;
    
    while ($n && $i < $MAXIFB) {
	if (!defined($MDB{"$i"}) || $MDB{"$i"} eq "" || $MDB{"$i"} eq "$vmid") {
	    $n--;
	}
	$i++;
    }
    if ($i == $MAXIFB || $n) {
	print STDERR "*** No more IFBs\n";
	dbmclose(%MDB);
	TBScriptUnlock();
	return undef;
    }
    #
    # Now allocate them.
    #
    $i = 0;
    $n = $needed;
    
    while ($n && $i < $MAXIFB) {
	if (!defined($MDB{"$i"}) || $MDB{"$i"} eq "" || $MDB{"$i"} eq "$vmid") {
	    $MDB{"$i"} = $vmid;
	    # Record ifb in use
	    $private->{'ifbs'}->{$i} = $i;
	    push(@ifbs, $i);
	    $n--;
	}
	$i++;
    }
    dbmclose(%MDB);
    TBScriptUnlock();
    return \@ifbs;
}

sub ReleaseIFBs($$)
{
    my ($vmid, $private) = @_;
    
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 1800) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }
    my %MDB;
    if (!dbmopen(%MDB, $IFBDB, 0660)) {
	print STDERR "*** Could not create $IFBDB\n";
	TBScriptUnlock();
	return -1;
    }
    #
    # Do not worry about what we think we have, just make sure we
    # have released everything assigned to this vmid. 
    #
    for (my $i = 0; $i < $MAXIFB; $i++) {
	if (defined($MDB{"$i"}) && $MDB{"$i"} eq "$vmid") {
	    $MDB{"$i"} = "";
	}
    }
    dbmclose(%MDB);
    TBScriptUnlock();
    delete($private->{'ifbs'});
    return 0;
}

#
# See if a route table already exists for the given tag, and if not,
# allocate it and return the table number.
#
sub AllocateRouteTable($)
{
    my ($token) = @_;
    my $rval = undef;

    if (! -e $RTDB && InitializeRouteTables()) {
	print STDERR "*** Could not initialize routing table DB\n";
	return undef;
    }
    my %RTDB;
    if (!dbmopen(%RTDB, $RTDB, 0660)) {
	print STDERR "*** Could not open $RTDB\n";
	return undef;
    }
    # Look for existing.
    for (my $i = 1; $i < $MAXROUTETTABLE; $i++) {
	if ($RTDB{"$i"} eq $token) {
	    $rval = $i;
	    print STDERR "Found routetable $i ($token)\n";
	    goto done;
	}
    }
    # Allocate a new one.
    for (my $i = 1; $i < $MAXROUTETTABLE; $i++) {
	if ($RTDB{"$i"} eq "") {
	    $RTDB{"$i"} = $token;
	    print STDERR "Allocate routetable $i ($token)\n";
	    $rval = $i;
	    goto done;
	}
    }
  done:
    dbmclose(%RTDB);
    return $rval;
}

sub LookupRouteTable($)
{
    my ($token) = @_;
    my $rval = undef;

    my %RTDB;
    if (!dbmopen(%RTDB, $RTDB, 0660)) {
	print STDERR "*** Could not open $RTDB\n";
	return undef;
    }
    # Look for existing.
    for (my $i = 1; $i < $MAXROUTETTABLE; $i++) {
	if ($RTDB{"$i"} eq $token) {
	    $rval = $i;
	    goto done;
	}
    }
  done:
    dbmclose(%RTDB);
    return $rval;
}

sub FreeRouteTable($)
{
    my ($token) = @_;
    
    my %RTDB;
    if (!dbmopen(%RTDB, $RTDB, 0660)) {
	print STDERR "*** Could not open $RTDB\n";
	return -1;
    }
    # Look for existing.
    for (my $i = 1; $i < $MAXROUTETTABLE; $i++) {
	if ($RTDB{"$i"} eq $token) {
	    $RTDB{"$i"} = "";
	    print STDERR "Free routetable $i ($token)\n";
	    last;
	}
    }
    dbmclose(%RTDB);
    return 0;
}

sub InitializeRouteTables()
{
    # Create clean route table DB and seed it with defaults.
    my %RTDB;
    if (!dbmopen(%RTDB, $RTDB, 0660)) {
	print STDERR "*** Could not create $RTDB\n";
	return -1;
    }
    # Clear all,
    for (my $i = 0; $i < $MAXROUTETTABLE; $i++) {
	$RTDB{"$i"} = ""
	    if (!defined($RTDB{"$i"}));
    }
    # Seed the reserved tables.
    if (! open(RT, $RTTABLES)) {
	print STDERR "*** Could not open $RTTABLES\n";
	return -1;
    }
    while (<RT>) {
	if ($_ =~ /^(\d*)\s*/) {
	    $RTDB{"$1"} = "$1";
	}
    }
    close(RT);
    dbmclose(%RTDB);
    return 0;
}

sub ReleaseRouteTables($$)
{
    my ($vmid, $private) = @_;
    
    if (TBScriptLock($GLOBAL_CONF_LOCK, 0, 1800) != TBSCRIPTLOCK_OKAY()) {
	print STDERR "Could not get the global lock after a long time!\n";
	return -1;
    }
    if (exists($private->{'routetables'})) {
	foreach my $token (keys(%{ $private->{'routetables'} })) {
	    if (FreeRouteTable($token) < 0) {
		TBScriptUnlock();
		return -1;
	    }
	    delete($private->{'routetables'}->{$token});
	}
    }

    TBScriptUnlock();
    return 0;
}

#
# Look inside a disk image and try to find the default kernel and
# ramdisk to boot. This should work for most of our standard images.
# Note that we use our own lightly hacked version of pygrub, that
# can look inside our images, and can hand simple submenus properly.
#
sub ExtractKernelFromLinuxImage($$)
{
    my ($lvname, $outdir) = @_;
    my $lvmpath = lvmVolumePath($lvname);
    my $PYGRUB  = "$BINDIR/pygrub";

    mysystem2("$PYGRUB --quiet --output-format=simple ".
	      "--output-directory=$outdir $lvmpath");
    return ()
	if ($?);
	    
    return ("$outdir/kernel", "$outdir/ramdisk");
}

sub ExtractKernelFromFreeBSDImage($$)
{
    my ($lvname, $outdir) = @_;
    my $lvmpath = lvmVolumePath($lvname);
    my $mntpath = "/mnt/$lvname";
    my $kernel  = undef;

    return undef
	if (! -e $mntpath && mysystem2("mkdir -p $mntpath"));

    mysystem2("mount -t ufs -o ro,ufstype=44bsd $lvmpath $mntpath");
    return undef
	if ($?);

    if (-e "$mntpath/boot/kernel/kernel" ||
	-e "$mntpath/boot/kernel.xen/kernel") {
	#
	# Use XEN kernel if it exists; Mike says he will start putting this
	# kernel into our FBSD images. 
	#
	my $kernelfile;

	if (-e "$mntpath/boot/kernel.xen/kernel") {
	    $kernelfile = "$mntpath/boot/kernel.xen/kernel";
	}
	else {
	    $kernelfile = "$mntpath/boot/kernel/kernel";

	    #
	    # See if there is a xen section. If not, then we cannot use it.
	    #
	    mysystem2("nm $kernelfile | grep -q xen_guest");
	    goto skip
		if ($?);
	}
	mysystem2("/bin/cp -pf $kernelfile $outdir/kernel");
	goto skip
	    if ($?);
	$kernel = "$outdir/kernel";
    }
  skip:
    mysystem2("umount $mntpath");
    return $kernel;
}

#
# Store and Load the image metadata (loadinfo data).
#
sub StoreImageMetadata($$)
{
    my ($metapath, $metadata) = @_;

    if (!open(META, ">$metapath")) {
	print STDERR "libvnode_xen: could not create $metapath\n";
	return -1;
    }
    foreach my $key (keys(%{$metadata})) {
	my $val = $metadata->{$key};
	print META "${key}=${val}\n";
    }
    close(META);
    return 0;
}
sub LoadImageMetadata($$)
{
    my ($imagename, $metadata) = @_;
    my $metapath = "$METAFS/${imagename}.metadata";
    my %result;

    if (!open(META, "$metapath")) {
	print STDERR "libvnode_xen: could not open $metapath\n";
	return -1;
    }
    while (<META>) {
	if ($_ =~ /^([-\w]*)\s*=\s*(.*)$/) {
	    my $key = $1;
	    my $val = $2;
	    $result{$key} = "$val";
	}
    }
    close(META);
    $$metadata = \%result;
    return 0;
}

#
# Fix up the initramfs so that it loads the xen-blkfront driver.
# This is really stupid and appears to be necessary on ubuntu.
#
sub FixRamFs($$)
{
    my ($vnode_id, $ramfspath)  = @_;
    my $tempdir = "$EXTRAFS/$vnode_id/ramfs";
    my $modules = "$EXTRAFS/$vnode_id/ramfs/conf/modules";

    return -1
	if (-e $tempdir && mysystem2("/bin/rm -rf $tempdir"));

    return -1
	if (mysystem2("mkdir -p $tempdir"));

    return -1
	if (mysystem2("cd $tempdir; zcat $ramfspath | cpio -i"));
    
    #
    # If there is a modules file, and it does not include the
    # the xen-blkfront module, add it. Then pack it back up and
    # copy back into place.
    #
    if (-e $modules) {
	if (mysystem2("grep -q xen-blkfront $modules") == 0) {
	    goto done;
	}
    }
    mysystem2("echo 'xen-blkfront' >> $modules");
    mysystem2("cd $tempdir; find . | cpio -H newc -o | gzip > $ramfspath");
    return -1
	if ($?);
done:
    mysystem2("/bin/rm -rf $tempdir");
    return 0;
}

1;


