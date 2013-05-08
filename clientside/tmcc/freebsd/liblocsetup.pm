#!/usr/bin/perl -wT
#
# Copyright (c) 2000-2013 University of Utah and the Flux Group.
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

#
# FreeBSD specific routines and constants for the client bootime setup stuff.
#
package liblocsetup;
use Exporter;
@ISA = "Exporter";
@EXPORT =
    qw ( $CP $EGREP $NFSMOUNT $UMOUNT $TMPASSWD $SFSSD $SFSCD $RPMCMD
	 $HOSTSFILE $LOOPBACKMOUNT $CHMOD
	 os_account_cleanup os_ifconfig_line os_etchosts_line
	 os_setup os_groupadd os_useradd os_userdel os_usermod os_mkdir
	 os_ifconfig_veth os_viface_name os_modpasswd
	 os_routing_enable_forward os_routing_enable_gated
	 os_routing_add_manual os_routing_del_manual os_homedirdel
	 os_groupdel os_getnfsmounts os_islocaldir os_mountextrafs
	 os_fwconfig_line os_fwrouteconfig_line os_config_gre os_nfsmount
	 os_find_freedisk os_get_ctrlnet_ip
	 os_init_storage os_check_storage os_create_storage os_remove_storage
	 os_getarpinfo os_createarpentry os_removearpentry
	 os_getstaticarp os_setstaticarp
       );

sub VERSION()	{ return 1.0; }

# Must come after package declaration!
use English;

# Load up the paths. Its conditionalized to be compatabile with older images.
# Note this file has probably already been loaded by the caller.
BEGIN
{

    if (-e "/etc/emulab/paths.pm") {
	require "/etc/emulab/paths.pm";
	import emulabpaths;
    }
    else {
	my $ETCDIR  = "/etc/testbed";
	my $BINDIR  = "/etc/testbed";
	my $VARDIR  = "/etc/testbed";
	my $BOOTDIR = "/etc/testbed";
    }
}
# Convenience.
sub REMOTE()	{ return libsetup::REMOTE(); }
sub REMOTEDED()	{ return libsetup::REMOTEDED(); }
sub MFS()	{ return libsetup::MFS(); }
sub JAILED()	{ return libsetup::JAILED(); }
sub INXENVM()   { return libsetup::INXENVM(); }

#
# Various programs and things specific to FreeBSD and that we want to export.
#
$CP		= "/bin/cp";
$DF		= "/bin/df";
$EGREP		= "/usr/bin/egrep -s -q";
$NFSMOUNT	= "/sbin/mount -o -b ";
$LOOPBACKMOUNT	= "/sbin/mount -t null ";
$MOUNT		= "/sbin/mount";
$UMOUNT		= "/sbin/umount";
$TMPASSWD	= "$ETCDIR/master.passwd";
$SFSSD		= "/usr/local/sbin/sfssd";
$SFSCD		= "/usr/local/sbin/sfscd";
$RPMCMD		= "/usr/local/bin/rpm";
$HOSTSFILE	= "/etc/hosts";
$WGET		= "/usr/local/bin/wget";
$CHMOD		= "/bin/chmod";
$ARP		= "/usr/sbin/arp";

#
# These are not exported
#
my $TMGROUP	= "$ETCDIR/group";
my $USERADD     = "/usr/sbin/pw useradd";
my $USERDEL     = "/usr/sbin/pw userdel";
my $USERMOD     = "/usr/sbin/pw usermod";
my $GROUPADD	= "/usr/sbin/pw groupadd";
my $GROUPDEL	= "/usr/sbin/pw groupdel";
my $CHPASS	= "/usr/bin/chpass -p";
my $MKDB	= "/usr/sbin/pwd_mkdb -p";
my $IFCONFIGBIN = "/sbin/ifconfig";
my $IFCONFIG    = "$IFCONFIGBIN %s inet %s netmask %s %s %s";
my $IFALIAS     = "$IFCONFIGBIN %s alias %s netmask %s";
my $IFC_1000MBS = "media 1000baseTX";
my $IFC_100MBS  = "media 100baseTX";
my $IFC_10MBS   = "media 10baseT/UTP";
my $IFC_FDUPLEX = "mediaopt full-duplex";
my $IFC_HDUPLEX = "mediaopt half-duplex";
my $MKDIR	= "/bin/mkdir";
my $GATED	= "/usr/local/sbin/gated";
my $ROUTE	= "/sbin/route";
my $SHELLS	= "/etc/shells";
my $DEFSHELL	= "/bin/tcsh";
my $ISCSI	= "/sbin/iscontrol";
my $ISCSICNF	= "/etc/iscsi.conf";
my $SMARTCTL	= "/usr/local/sbin/smartctl";

#
# OS dependent part of account cleanup. On a remote node, this will
# only be called from inside a JAIL, or from the prepare script.
#
sub os_account_cleanup($)
{
    # XXX this stuff should be lifted up into rc.accounts, sigh
    my ($updatemasterpasswdfiles) = @_;
    if (!defined($updatemasterpasswdfiles)) {
	$updatemasterpasswdfiles = 0;
    }

    printf STDOUT "Resetting passwd and group files\n";
    if (system("$CP -f $TMGROUP /etc/group") != 0) {
	print STDERR "Could not copy default group file into place: $!\n";
	return -1;
    }

    if (system("$CP -f $TMPASSWD /etc/master.passwd_testbed") != 0) {
	print STDERR "Could not copy default passwd file into place: $!\n";
	return -1;
    }

    if (system("$MKDB /etc/master.passwd_testbed") != 0) {
	print STDERR "Failure running $MKDB on default password file: $!\n";
	return -1;
    }
    return 0;
}

#
# Generate and return an ifconfig line that is approriate for putting
# into a shell script (invoked at bootup).
#
sub os_ifconfig_line($$$$$$$$;$$%)
{
    my ($iface, $inet, $mask, $speed, $duplex, $aliases, $iface_type, $lan,
	$settings, $rtabid, $cookie) = @_;
    my $media    = "";
    my $mediaopt = "";
    my ($uplines, $downlines);

    #
    # Need to check units on the speed. Just in case.
    #
    if (!INXENVM()) {
	if ($speed =~ /(\d*)([A-Za-z]*)/) {
	    if ($2 eq "Mbps") {
		$speed = $1;
	    }
	    elsif ($2 eq "Kbps") {
		$speed = $1 / 1000;
	    }
	    else {
		warn("*** Bad speed units $2 in ifconfig, default to 100Mbps\n");
		$speed = 100;
	    }
	    if ($speed == 10000) {
		# 10G is 10G, take it or leave it
		$media = "";
	    }
	    elsif ($speed == 1000) {
		$media = $IFC_1000MBS;
	    }
	    elsif ($speed == 100) {
		$media = $IFC_100MBS;
	    }
	    elsif ($speed == 10) {
		$media = $IFC_10MBS;
	    }
	    else {
		warn("*** Bad Speed $speed in ifconfig, default to 100Mbps\n");
		$speed = 100;
		$media = $IFC_100MBS;
	    }
	}

	if ($duplex eq "full") {
	    if ($speed == 10000) {
		# 10G is always full duplex, no need to set
		$mediaopt = "";
	    } else {
		$mediaopt = $IFC_FDUPLEX;
	    }
	}
	elsif ($duplex eq "half") {
	    $mediaopt = $IFC_HDUPLEX;
	}
	else {
	    warn("*** Bad duplex $duplex in ifconfig, default to full\n");
	    $duplex = "full";
	    $mediaopt = $IFC_FDUPLEX;
	}
    }

    $uplines = "";

    if ($inet eq "") {
	$uplines .= "$IFCONFIGBIN $iface up $media $mediaopt";
    }
    else {
	#
	# Must set route table id before assigning IP address so that interface
	# route winds up in the correct table.
	#
	if (defined($rtabid)) {
	    $uplines .= "$IFCONFIGBIN $iface rtabid $rtabid\n    ";
	}

	# Config the interface.
	$uplines  .= sprintf($IFCONFIG, $iface, $inet, $mask,
			     $media, $mediaopt);
	# An interface underlying virtual interfaces does not go down.
	$downlines = "$IFCONFIGBIN $iface down"
	    if (defined($lan) && $lan ne "");
    }
    return ($uplines, $downlines);
}

#
# Specialized function for configing virtual ethernet devices:
#
#	'veth'	locally hacked veth devices
#	'vlan'	802.1q tagged vlan devices
#	'alias'	IP aliases on physical interfaces
#
sub os_ifconfig_veth($$$$$;$$$$$)
{
    my ($iface, $inet, $mask, $id, $vmac,
	$rtabid, $encap, $vtag, $itype, $cookie) = @_;
    my ($uplines, $downlines);

    #
    # Do not try this on the MFS!
    #
    return ""
	if (MFS());

    require Socket;
    import Socket;

    if ($itype !~ /^(alias|vlan|veth)$/) {
	warn("Unknown virtual interface type $itype\n");
	return "";
    }

    #
    # IP aliases
    #
    if ($itype eq "alias") {
	# Must do this first to avoid lo0 routes.
	if (!exists($cookie->{"alias"})) {
	    $uplines =
	      "sysctl net.link.ether.inet.useloopback=0 >/dev/null 2>&1\n    ";
	    $cookie->{"alias"} = 1;
	}

	$uplines   .= sprintf($IFALIAS, $iface, $inet, $mask);
	$downlines .= "$IFCONFIGBIN $iface -alias $inet";

	return ($uplines, $downlines);
    }

    #
    # VLANs
    #
    if ($itype eq "vlan") {
	if (!defined($vtag)) {
	    warn("No vtag in veth config\n");
	    return "";
	}

	$uplines = "$IFCONFIGBIN vlan${id} create link " .
		   "vlan $vtag vlandev $iface\n    ";

	$encap = 1;
    }

    #
    # VETHs
    #
    else {
	if (!defined($vtag)) {
	    # Need to derive a vlan tag. Just use the middle two octets.
	    my $vtag = (unpack("I", inet_aton($inet)) >> 8) & 0xffff;
	}

	if ($vmac =~ /^(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})$/) {
	    $vmac = "$1:$2:$3:$4:$5:$6";
	}
	else {
	    warn("Bad vmac in veth config: $vmac\n");
	    return "";
	}

	$uplines = "$IFCONFIGBIN veth${id} create\n    " .
		   "$IFCONFIGBIN veth${id} vethaddr $vmac/$vtag" .
		       (defined($iface) ? " vethdev $iface\n    " : "\n    ");
    }

    #
    # Must set route table id before assigning IP address so that interface
    # route winds up in the correct table.
    #
    if (defined($rtabid)) {
	$uplines .= "$IFCONFIGBIN ${itype}${id} rtabid $rtabid\n    ";
    }

    $uplines .= "$IFCONFIGBIN ${itype}${id} inet $inet netmask $mask";

    #
    # link1 on the veth device implies no encapsulation
    #
    if (!$encap) {
	$uplines .= " link1";
    }

    $downlines = "$IFCONFIGBIN ${itype}${id} destroy";

    return ($uplines, $downlines);
}

#
# Compute the name of a virtual interface device based on the
# information in ifconfig hash (as returned by getifconfig).
#
sub os_viface_name($)
{
    my ($ifconfig) = @_;
    my $piface = $ifconfig->{"IFACE"};

    #
    # Physical interfaces use their own name
    #
    if (!$ifconfig->{"ISVIRT"}) {
	return $piface;
    }

    #
    # Otherwise we have a virtual interface: alias, veth, vlan.
    #
    # alias: There is no alias device, just use the phys device
    # veth:  veth<ID>
    # vlan:  vlan<ID>
    #
    my $itype = $ifconfig->{"ITYPE"};
    if ($itype eq "alias") {
	return $piface;
    } elsif ($itype =~ /^(vlan|veth)$/) {
	return $itype . $ifconfig->{"ID"};
    }

    warn("FreeBSD does not support virtual interface type '$itype'\n");
    return undef;
}

#
# Generate and return an string that is approriate for putting
# into /etc/hosts.
#
sub os_etchosts_line($$$)
{
    my ($name, $ip, $aliases) = @_;

    return sprintf("%s\t%s %s", $ip, $name, $aliases);
}

#
# Add a new group
#
sub os_groupadd($$)
{
    my($group, $gid) = @_;

    return system("$GROUPADD $group -g $gid");
}

#
# Delete an old group
#
sub os_groupdel($)
{
    my($group) = @_;

    return system("$GROUPDEL $group");
}

#
# Remove a user account.
#
sub os_userdel($)
{
    my($login) = @_;

    return system("$USERDEL $login");
}

#
# Modify user group membership.
#
sub os_usermod($$$$$$)
{
    my($login, $gid, $glist, $pswd, $root, $shell) = @_;

    if ($root) {
	$glist = join(',', split(/,/, $glist), "wheel");
    }
    if ($glist ne "") {
	$glist = "-G $glist";
    }
    # Map the shell into a full path.
    $shell = MapShell($shell);

    if (system("$CHPASS '$pswd' $login") != 0) {
	warn "*** WARNING: $CHPASS $login error.\n";
	return -1;
    }
    return system("$USERMOD $login -s $shell -g $gid $glist");
}

#
# Add a user.
#
sub os_useradd($$$$$$$$$)
{
    my($login, $uid, $gid, $pswd, $glist, $homedir, $gcos, $root, $shell) = @_;
    my $args = "";

    if ($root) {
	$glist = join(',', split(/,/, $glist), "wheel");
    }
    if ($glist ne "") {
	$args .= "-G $glist ";
    }
    # If remote, let it decide where to put the homedir.
    if (!REMOTE()) {
	$args .= "-d $homedir ";

	# Locally, if directory exists and is populated, skip -m
	# cause FreeBSD copies files in anyway!
	$args .= "-m "
	    if (! -d $homedir || ! -e "$homedir/.cshrc");
    }
    else {
	# populate on remote nodes. At some point will tar files over.
	$args .= "-m ";
    }

    # Map the shell into a full path.
    $shell = MapShell($shell);

    if (system("$USERADD $login -u $uid -g $gid $args ".
	       "-s $shell -c \"$gcos\"") != 0) {
	warn "*** WARNING: $USERADD $login error.\n";
	return -1;
    }
    chown($uid, $gid, $homedir);

    if (system("$CHPASS '$pswd' $login") != 0) {
	warn "*** WARNING: $CHPASS $login error.\n";
	return -1;
    }
    return 0;
}

#
# Modify user password
#
sub os_modpasswd($$)
{
    my($login, $pswd) = @_;

    if (system("$CHPASS '$pswd' $login") != 0) {
	warn "*** WARNING: $CHPASS $login error.\n";
	return -1;
    }
    if ($login eq "root" &&
	system("$CHPASS '$pswd' toor") != 0) {
	warn "*** WARNING: $CHPASS $login error.\n";
	return -1;
    }
    return 0;
}

#
# Remove a homedir. Might someday archive and ship back.
#
sub os_homedirdel($$)
{
    return 0;
}

#
# Create a directory including all intermediate directories.
#
sub os_mkdir($$)
{
    my ($dir, $mode) = @_;

    if (system("$MKDIR -p -m $mode $dir")) {
	return 0;
    }
    return 1;
}

#
# OS Dependent configuration.
#
sub os_setup()
{
    # This should never happen!
    if ((REMOTE() && !REMOTEDED()) || MFS()) {
	print "Ignoring os setup on remote/MFS node!\n";
	return 0;
    }
}

#
# OS dependent, routing-related commands
#
sub os_routing_enable_forward()
{
    my $cmd;
    my $fname = libsetup::ISDELAYNODEPATH();

    if (REMOTE() && !REMOTEDED()) {
	$cmd = "echo 'IP forwarding not turned on!'";
    }
    elsif (JAILED()) {
	$cmd = "# IP forwarding is enabled outside the jail";
    } else {
	# No Fast Forwarding when operating with linkdelays.
	$cmd  = "sysctl net.inet.ip.forwarding=1\n" .
	        "    if [ ! -e $fname ]; then\n" .
	        "        sysctl net.inet.ip.fastforwarding=1\n" .
		"    fi\n";
    }
    return $cmd;
}

sub os_routing_enable_gated($)
{
    my ($conffile) = @_;
    my $cmd;

    if (REMOTE() && !REMOTEDED()) {
	$cmd = "echo 'GATED IS NOT ALLOWED!'";
    }
    else {
	$cmd = "$GATED -f $conffile";
    }
    return $cmd;
}

sub os_routing_add_manual($$$$$;$)
{
    my ($routetype, $destip, $destmask, $gate, $cost, $rtabid) = @_;
    my $cmd;
    my $rtabopt = (defined($rtabid) ? "-rtabid $rtabid" : "");

    if ($routetype eq "host") {
	$cmd = "$ROUTE add $rtabopt -host $destip $gate";
    } elsif ($routetype eq "net") {
	$cmd = "$ROUTE add $rtabopt -net $destip $gate $destmask";
    } elsif ($routetype eq "default") {
	$cmd = "$ROUTE add $rtabopt default $gate";
    } else {
	warn "*** WARNING: bad routing entry type: $routetype\n";
	$cmd = "false";
    }

    return $cmd;
}

sub os_routing_del_manual($$$$$;$)
{
    my ($routetype, $destip, $destmask, $gate, $cost, $rtabid) = @_;
    my $cmd;
    my $rtabopt = (defined($rtabid) ? "-rtabid $rtabid" : "");

    if ($routetype eq "host") {
	$cmd = "$ROUTE delete $rtabopt -host $destip";
    } elsif ($routetype eq "net") {
	$cmd = "$ROUTE delete $rtabopt -net $destip $gate $destmask";
    } elsif ($routetype eq "default") {
	$cmd = "$ROUTE delete $rtabopt default";
    } else {
	warn "*** WARNING: bad routing entry type: $routetype\n";
	$cmd = "false";
    }

    return $cmd;
}

# Map a shell name to a full path using /etc/shells
sub MapShell($)
{
   my ($shell) = @_;

   if ($shell eq "") {
       return $DEFSHELL;
   }

   my $fullpath = `grep '/${shell}\$' $SHELLS`;

   if ($?) {
       return $DEFSHELL;
   }

   # Sanity Check
   if ($fullpath =~ /^([-\w\/]*)$/) {
       $fullpath = $1;
   }
   else {
       $fullpath = $DEFSHELL;
   }
   return $fullpath;
}

# Return non-zero if given directory is on a "local" filesystem
sub os_islocaldir($)
{
    my ($dir) = @_;
    my $rv = 0;

    #
    # XXX 'df -l' doesn't do the right thing on older FreeBSD
    # so we compare what df returns to the mount table.  If the current
    # hack doesn't work, we will now err on the safe side and say the
    # homedir is remote, since our caller only gets destructive if the
    # homedir is local.
    #
    my $dfoutput = `$DF -l $dir | grep -v -i filesystem 2>/dev/null`;
    my $mdev = (split('\s+', $dfoutput))[0];
    if ($mdev) {
	my $mountout = `$MOUNT | grep $mdev`;
	if ($mountout && $mountout ne "" && $mountout !~ /\(nfs/) {
	    $rv = 1;
	}
    }
    return $rv;
}

#
# Find out what NFS mounts exist already!
#
sub os_getnfsmounts($)
{
    my ($rptr) = @_;
    my %mounted = ();

    #
    # Grab the output of the mount command and parse.
    #
    if (! open(MOUNT, "$MOUNT|")) {
	print "os_getnfsmounts: Cannot run mount command\n";
	return -1;
    }
    while (<MOUNT>) {
	if ($_ =~ /^([-\w\.\/:\(\)]+) on ([-\w\.\/]+) \((.*)\)$/) {
	    # Search for nfs string in the option list.
	    foreach my $opt (split(',', $3)) {
		if ($opt eq "nfs") {
		    $mounted{$1} = $2;
		}
	    }
	}
    }
    close(MOUNT);
    %$rptr = %mounted;
    return 0;
}

sub os_fwconfig_line($@)
{
    my ($fwinfo, @fwrules) = @_;
    my ($upline, $downline);

    if ($fwinfo->{TYPE} ne "ipfw" && $fwinfo->{TYPE} ne "ipfw2-vlan") {
	warn "*** WARNING: unsupported firewall type '", $fwinfo->{TYPE}, "'\n";
	return ("false", "false");
    }

    # XXX debugging
    my $logaccept = defined($fwinfo->{LOGACCEPT}) ? $fwinfo->{LOGACCEPT} : 0;
    my $logreject = defined($fwinfo->{LOGREJECT}) ? $fwinfo->{LOGREJECT} : 0;
    my $dotcpdump = defined($fwinfo->{LOGTCPDUMP}) ? $fwinfo->{LOGTCPDUMP} : 0;

    #
    # Convert MAC info to a useable form and filter out the firewall itself
    #
    my $href = $fwinfo->{MACS};
    while (my ($node,$mac) = each(%$href)) {
	if ($mac eq $fwinfo->{OUT_IF}) {
	    delete($$href{$node});
	} elsif ($mac =~ /^(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})$/) {
	    $$href{$node} = "$1:$2:$3:$4:$5:$6";
	} else {
	    warn "*** WARNING: Bad MAC returned for $node in fwinfo: $mac\n";
	    return ("false", "false");
	}
    }
    $href = $fwinfo->{SRVMACS};
    while (my ($node,$mac) = each(%$href)) {
	if ($mac eq $fwinfo->{OUT_IF}) {
	    delete($$href{$node});
	} elsif ($mac =~ /^(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})$/) {
	    $$href{$node} = "$1:$2:$3:$4:$5:$6";
	} else {
	    warn "*** WARNING: Bad MAC returned for $node in fwinfo: $mac\n";
	    return ("false", "false");
	}
    }

    #
    # VLAN enforced layer2 firewall with FreeBSD/IPFW2
    #
    if ($fwinfo->{TYPE} eq "ipfw2-vlan") {
	if (!defined($fwinfo->{IN_VLAN})) {
	    warn "*** WARNING: no VLAN for ipfw2-vlan firewall, NOT SETUP!\n";
	    return ("false", "false");
	}

	my $vlandev = "vlan0";
	my $vlanno  = $fwinfo->{IN_VLAN};
	my $pdev    = `$BINDIR/findif $fwinfo->{IN_IF}`;
	chomp($pdev);

	$upline  = "ifconfig $vlandev create link vlan $vlanno vlandev $pdev\n";
	$upline .= "    if [ -z \"`sysctl net.link.ether.bridge 2>/dev/null`\" ]; then\n";
	$upline .= "        kldload bridge.ko >/dev/null 2>&1\n";
	$upline .= "    fi\n";
	$upline .= "    sysctl net.link.ether.bridge_vlan=0\n";
	$upline .= "    sysctl net.link.ether.bridge_ipfw=1\n";
	$upline .= "    sysctl net.link.ether.ipfw=0\n";
	$upline .= "    sysctl net.link.ether.bridge_cfg=$vlandev,$pdev\n";
	$upline .= "    if [ -z \"`sysctl net.inet.ip.fw.enable 2>/dev/null`\" ]; then\n";
	$upline .= "        kldload ipfw.ko >/dev/null 2>&1\n";
	$upline .= "    fi\n";

	#
	# Setup proxy ARP entries.
	#
	# Since we want to control which entries are proxied on inside/outside
	# we use our multiple routing table support and put the inside IF
	# into a different routing domain.  Then we can enter entries into
	# one routing table or the other.
	#
	# XXX this blows: in order to enter an ARP entry on the vlan0
	# interface, it has to be configured with an address in the same
	# subnet.  So we give vlan0 our same address (the beauty of separate
	# routing tables).  This *shouldn't* confuse anything on the firewall.
	#
	if (defined($fwinfo->{MACS})) {
	    my $myip = `cat $BOOTDIR/myip`;
	    chomp($myip);
	    my $mymask = `cat $BOOTDIR/mynetmask`;
	    chomp($mymask);

	    $upline .=
		"    ifconfig $vlandev inet $myip netmask $mymask rtabid 2\n";

	    # publish servers (including GW) on inside and for us on outside
	    if (defined($fwinfo->{SRVMACS})) {
		my $href = $fwinfo->{SRVMACS};
		while (my ($ip,$mac) = each %$href) {
		    $upline .= "    arp -r 2 -s $ip $mac pub only\n";
		    $upline .= "    arp -s $ip $mac\n";
		}
	    }

	    # provide node MACs to outside, and unpublished on inside for us
	    my $href = $fwinfo->{MACS};
	    while (my ($node,$mac) = each %$href) {
		$upline .= "    arp -s $node $mac pub only\n";
		$upline .= "    arp -r 2 -s $node $mac\n";
	    }
	}
	foreach my $rule (sort { $a->{RULENO} <=> $b->{RULENO}} @fwrules) {
	    my $rulestr = $rule->{RULE};
	    if ($logaccept && $rulestr =~ /^(allow|accept|pass|permit)\s.*/) {
		my $action = $1;
		$rulestr =~ s/$action/$action log/;
	    } elsif ($logreject && $rulestr =~ /^(deny|drop)\s.*/) {
		my $action = $1;
		$rulestr =~ s/$action/$action log/;
	    }

	    $upline .= "    ipfw add $rule->{RULENO} $rulestr || {\n";
	    $upline .= "        echo 'WARNING: could not load ipfw rule:'\n";
	    $upline .= "        echo '  $rulestr'\n";
	    $upline .= "        ipfw -q flush\n";
	    $upline .= "        exit 1\n";
	    $upline .= "    }\n";
	}

	if ($dotcpdump) {
	    $upline .= "    tcpdump -i $vlandev ".
		"-w $LOGDIR/in.tcpdump >/dev/null 2>&1 &\n";
	    $upline .= "    tcpdump -i $pdev ".
		"-w $LOGDIR/out.tcpdump not vlan >/dev/null 2>&1 &\n";
	}

	if ($logaccept || $logreject) {
	    $upline .= "    sysctl net.inet.ip.fw.verbose=1\n";
	}
	$upline .= "    sysctl net.inet.ip.fw.enable=1 || {\n";
	$upline .= "        echo 'WARNING: could not enable firewall'\n";
	$upline .= "        exit 1\n";
	$upline .= "    }\n";
	$upline .= "    sysctl net.link.ether.bridge=1";

	#
	# XXX maybe we should be more careful to ensure that the bridge
	# is really down before turning off the firewall.  OTOH, if
	# someone has really hacked the firewall to the extent that they
	# can prevent us from shutting down the bridge, then they should
	# be quite capable of taking down the firewall on their own.
	#
	$downline  = "sysctl net.link.ether.bridge=0 || {\n";
	$downline .= "        echo 'WARNING: could not disable bridge'\n";
	$downline .= "        echo '         firewall left enabled'\n";
	$downline .= "        exit 1\n";
	$downline .= "    }\n";
	$downline .= "    sysctl net.inet.ip.fw.enable=0\n";
	if ($dotcpdump) {
	    $downline .= "    killall tcpdump >/dev/null 2>&1\n";
	}
	if ($logaccept || $logreject) {
	    $downline .= "    sysctl net.inet.ip.fw.verbose=0\n";
	}
	$downline .= "    ipfw -q flush\n";
	$downline .= "    sysctl net.link.ether.bridge_cfg=\"\"\n";
	$downline .= "    sysctl net.link.ether.bridge_ipfw=0\n";
	$downline .= "    sysctl net.link.ether.bridge_vlan=1\n";
	if (defined($fwinfo->{MACS})) {
	    my $href = $fwinfo->{MACS};
	    while (my ($node,$mac) = each %$href) {
		$downline .= "    arp -d $node pub\n";
		$downline .= "    arp -r 2 -d $node\n";
	    }
	}
	$downline .= "    ifconfig $vlandev destroy";

	return ($upline, $downline);
    }

    #
    # Voluntary IP firewall with FreeBSD/IPFW
    #
    $upline  = "if [ -z \"`sysctl net.inet.ip.fw.enable 2>/dev/null`\" ]; then\n";
    $upline .= "        kldload ipfw.ko >/dev/null 2>&1\n";
    $upline .= "    fi\n";

    foreach my $rule (sort { $a->{RULENO} <=> $b->{RULENO}} @fwrules) {
	my $rulestr = $rule->{RULE};
	if ($logaccept && $rulestr =~ /^(allow|accept|pass|permit)\s.*/) {
	    my $action = $1;
	    $rulestr =~ s/$action/$action log/;
	} elsif ($logreject && $rulestr =~ /^(deny|drop)\s.*/) {
	    my $action = $1;
	    $rulestr =~ s/$action/$action log/;
	}

	$upline .= "    ipfw add $rule->{RULENO} $rulestr || {\n";
	$upline .= "        echo 'WARNING: could not load ipfw rule:'\n";
	$upline .= "        echo '  $rulestr'\n";
	$upline .= "        ipfw -q flush\n";
	$upline .= "        exit 1\n";
	$upline .= "    }\n";
    }
    $upline .= "    sysctl net.inet.ip.fw.enable=1 || {\n";
    $upline .= "        echo 'WARNING: could not enable firewall'\n";
    $upline .= "        exit 1\n";
    $upline .= "    }\n";
    $upline .= "    sysctl net.inet.ip.redirect=0\n";
    $upline .= "    sysctl net.inet.ip.forwarding=1";

    $downline  = "sysctl net.inet.ip.forwarding=0\n";
    $downline .= "    sysctl net.inet.ip.redirect=1\n";
    $downline .= "    ipfw -q flush\n";
    $downline .= "    kldunload ipfw.ko >/dev/null 2>&1";

    return ($upline, $downline);
}

sub os_fwrouteconfig_line($$$)
{
    my ($orouter, $fwrouter, $routestr) = @_;
    my ($upline, $downline);

    #
    # XXX assume the original default route should be used to reach servers.
    #
    # For setting up the firewall, this means we create explicit routes for
    # each host via the original default route.
    #
    # For tearing down the firewall, we just remove the explicit routes
    # and let them fall back on the now re-established original default route.
    #
    $upline  = "for vir in $routestr; do\n";
    $upline .= "        $ROUTE -q delete \$vir >/dev/null 2>&1\n";
    $upline .= "        $ROUTE -q add \$vir $orouter || {\n";
    $upline .= "            echo \"Could not establish route for \$vir\"\n";
    $upline .= "            exit 1\n";
    $upline .= "        }\n";
    $upline .= "    done";

    $downline  = "for vir in $routestr; do\n";
    $downline .= "        $ROUTE -q delete \$vir >/dev/null 2>&1\n";
    $downline .= "    done";

    return ($upline, $downline);
}

sub os_config_gre($$$$$$$)
{
    my ($name, $unit, $inetip, $peerip, $mask, $srchost, $dsthost) = @_;

    my $gre = `ifconfig gre create`;
    if ($?) {
	warn("*** Could not create a new gre device.\n");
	return -1;
    }
    if ($gre =~ /^(gre\d*)$/) {
	$gre = $1;
    }
    else {
	warn("*** Cannot parse gre device '$gre'\n");
	return -1;
    }
    if (system("ifconfig $gre $inetip $peerip link1 netmask $mask up") ||
	system("ifconfig $gre tunnel $srchost $dsthost")) {
	warn("Could not start tunnel!\n");
	return -1;
    }
    return 0;
}

sub os_get_disks
{
    my @disks;
    my $dmesgpat = "^([a-z]+\\d+):.* (\\d+)MB.*\$";

    for my $cmd ("/sbin/dmesg", "cat /var/run/dmesg.boot") {
	    my @cmdout = `$cmd`;
	    foreach my $line (@cmdout) {
		if ($line =~ /$dmesgpat/) {
		    my $name = $1;

		    push @disks, $name;
		}
	    }

	    last if (@disks);
    }

    return @disks;
}

sub os_get_ctrlnet_ip
{
	my $iface;
	my $address;

	# just use recorded IP if available
	if (-e "$BOOTDIR/myip") {
	    $myip = `cat $BOOTDIR/myip`;
	    chomp($myip);
	    return $myip;
	}

	if (!open CONTROLIF, "$BOOTDIR/controlif") {
		return undef;
	}

	$iface = <CONTROLIF>;
	chomp $iface;

	$iface =~ /(.*)/;
	$iface = $1;

	close CONTROLIF;

	if (!open IFCFG, "$IFCONFIGBIN $iface|") {
		return undef;
	}

	while (<IFCFG>) {
		if (/inet ([0-9.]*) /) {
			$address = $1;
			last;
		}
	}

	close IFCFG;

	return $address;
}

sub os_get_disk_size($)
{
    my ($disk) = @_;
    my $size;

    $disk =~ s#^/dev/##;

    my @cmdout = `$cmd`;

    my $dmesgpat = "^($disk\\d+):.* (\\d+)MB.*\$";
    foreach my $line (@cmdout) {
	if ($line =~ /$dmesgpat/) {
	    my $size = $2;
	    last;
	}
    }

    return $size;
}

sub os_get_partition_info($$)
{
    my ($bootdev, $partition) = @_;

    if (!open(FDISK, "fdisk -s $bootdev |")) {
	print("Failed to run fdisk on $bootdev!");
	return -1;
    }

    # First line looks like "/dev/ad0: 5005 cyl 255 hd 63 sec"
    my $line = <FDISK>;
    if (!defined($line)) {
	print("No fdisk summary info for MBR on $bootdev!\n");
	goto bad;
    }
    if (! ($line =~ /^.*cyl (\d*) hd (\d*) sec/)) {
	print("Invalid fdisk summary info for MBR on $bootdev!\n");
	goto bad;
    }
    while (<FDISK>) {
	if ($_ =~ /^\s*(\d):\s*\d*\s*(\d*)\s*(0x[\w]*)\s*0x[\w]*$/) {
	    if ($1 == $partition) {
		my $plen = $2;
		my $ptype = hex($3);
		close(FDISK);
		return ($plen, $ptype);
	    }
	}
    }
    print("No such partition in fdisk summary info for MBR on $bootdev!\n");
  bad:
    close(FDISK);
    return -1;
}

sub os_nfsmount($$)
{
    my ($remote,$local) = @_;

    if (system("$NFSMOUNT $remote $local")) {
	return 1;
    }

    return 0;
}

#
# Create/mount a local filesystem on the extra partition if it hasn't
# already been done.  Returns the resulting mount point (which may be
# different than what was specified as an argument if it already existed).
#
sub os_mountextrafs($)
{
    my $dir = shift;
    my $mntpt = "";
    my $log = "$VARDIR/logs/mkextrafs.log";

    #
    # XXX this is a most bogus hack right now, we look for partition 4
    # in /etc/fstab.
    #
    my $fstabline = `grep 0s4e /etc/fstab`;
    if ($fstabline =~ /^\/dev\/\S*0s4e\s+(\S+)\s+/) {
	$mntpt = $1;
    } elsif (!system("$BINDIR/mkextrafs.pl -f $dir >$log 2>&1")) {
	$mntpt = $dir;
    } else {
	print STDERR "mkextrafs failed, see $log\n";
    }
    return $mntpt;
}

#
# Find unused disk space on a machine.
#
# A spare disk or disk partition is one whose partition ID is zero and is
# "inactive" (not mounted or in use as a swap partition).
#
# If $allparts is non-zero, then we also consider inactive partitions with
# non-zero IDs.
#
# This function returns a hash of:
#   device name (disk) => slice/part number => size (bytes);
# note that a device name => size entry is filled IF the device has no
# partitions.
#
# XXX assumes MBR and not GPT.  GPT-based disks might well appear available,
# we should fix that!
#
sub os_find_freedisk($$)
{
    my ($minsize,$allparts) = @_;
    my %diskinfo = ();

    #
    # Use sysctl to locate disks.
    #
    my @disks = split /\s+/, `sysctl -n kern.disks 2>/dev/null`;
    return %diskinfo if ($?);
    print STDERR "disks: ", join('/', @disks), "\n" if ($debug);

    #
    # Capture all mounted devices
    #
    my %mounts;
    if (!open(FD, "/sbin/mount|")) {
	print STDERR "find_freedisk: cannot read mount info\n";
	return %diskinfo;
    }
    while (<FD>) {
	if (/^\/dev\/(\S+)/) {
	    my $dev = $1;
	    $mounts{$dev} = 1;
	    # full <disk><slice><part> syntax, mark components as "mounted"
	    if ($dev =~ /^(\D+\d+)(s\d+)([a-z])$/) {
		$mounts{"$1$2"} = 2;
		$mounts{$1} = 2;
	    }
	    # <disk><slice> syntax, ditto
	    elsif ($dev =~ /^(\D+\d+)(s\d+)$/) {
		$mounts{$1} = 2;
	    }
	}
    }
    close(FD);

    #
    # Count active swap partitions as mounted
    #
    if (!open(FD, "/usr/sbin/swapinfo|")) {
	print STDERR "find_freedisk: cannot read swap info\n";
	return %diskinfo;
    }
    while (<FD>) {
	if (/^\/dev\/(\S+)/) {
	    my $dev = $1;
	    $mounts{$dev} = 1;
	    # full <disk><slice><part> syntax, mark components as "mounted"
	    if ($dev =~ /^(\D+\d+)(s\d+)([a-z])$/) {
		$mounts{"$1$2"} = 2;
		$mounts{$1} = 2;
	    }
	    # <disk><slice> syntax, ditto
	    elsif ($dev =~ /^(\D+\d+)(s\d+)$/) {
		$mounts{$1} = 2;
	    }
	}
    }
    close(FD);

    print STDERR "found mounts: ", join('/', sort keys %mounts), "\n" if ($debug);

    #
    # For each disk, find any unused space
    #
    foreach my $disk (sort @disks) {
	#
	# Find size of disk
	#
	my $dinfo = `diskinfo $disk 2>/dev/null`;
	if ($?) {
	    print STDERR "find_freedisk: $disk: could not open\n";
	    next;
	}
	my ($dname,$dsecsize,$dbytes,$dsects) = split /\s+/, $dinfo;
	if ($dname ne $disk ||
	    !defined($dsecsize) || !defined($dbytes) || !defined($dsects)) {
	    print STDERR "find_freedisk: $disk: could not parse diskinfo\n";
	    next;
	}
	print STDERR "$disk: has $dsects $dsecsize byte sectors\n" if ($debug);

	#
	# See how it is partitioned.
	#
	if (!open(FD, "fdisk -s $disk 2>&1|")) {
	    print STDERR "find_freedisk: $disk: could not get partitions\n";
	    next;
	}
	while (<FD>) {
	    #
	    # No MBR should mean that the entire disk is unused.
	    # But we make sure there are no mounts anywhere on the
	    # disk just to be safe.
	    #
	    if (/invalid fdisk partition table found/ &&
		!defined($mounts{$disk})) {
		print STDERR "$disk: disk: size=$dbytes\n" if ($debug);
		if ($dbytes >= $minsize) {
		    $diskinfo{$disk}{"size"} = $dbytes;
		    $diskinfo{$disk}{"type"} = 0;
		}
		last;
	    }

	    #
	    # Otherwise fdisk output looks like:
	    #
	    #  /dev/da0: 30394 cyl 255 hd 63 sec
	    #  Part        Start Size     Type Flags
	    #  1:          63    12305790 0xa5 0x80
	    #  ...
	    #
	    if (/^\s*([1-4]):\s+\d+\s+(\d+)\s+(0x\S\S)\s+/) {
		my $part = "s$1";
		my $size = $2;
		my $type = hex($3);
		if ($type == 0) {
		    $size *= $dsecsize;
		    print STDERR "$disk$part: part: size=$size\n" if ($debug);
		    if ($size >= $minsize) {
			$diskinfo{$disk}{$part}{"size"} = $size;
			$diskinfo{$disk}{$part}{"type"} = 0;
		    }
		} else {
		    #
		    # If type is non-zero but partition isn't mounted
		    # and $allparts is non-zero, we return it.
		    #
		    if ($allparts && !exists($mounts{"$disk$part"})) {
			$size *= $dsecsize;
			print STDERR "$disk$part: part: size=$size, in use ($type) not mounted\n"
			    if ($debug);
			if ($size >= $minsize) {
			    $diskinfo{$disk}{$part}{"size"} = $size;
			    $diskinfo{$disk}{$part}{"type"} = $type;
			}
		    } else {
			print STDERR "$disk$part: part: size=$size, in use ($type)\n"
			    if ($debug);
		    }
		}
	    }

	    #
	    # XXX right now we are not going to drill down into disklabels
	    # to look for unused space.
	    #
	}
	close(FD);
    }

    return %diskinfo;
}

#
# Read the current arp info and create a hash for it.
#
sub os_getarpinfo($$)
{
    my ($diface,$airef) = @_;
    my %arpinfo = ();

    if (!open(ARP, "$ARP -a|")) {
	print "os_getarpinfo: Cannot run arp command\n";
	return 1;
    }

    while (<ARP>) {
	if (/^(\S+) \(([\d\.]+)\) at (..:..:..:..:..:..) on (\S+) (.*)/) {
	    my $name = $1;
	    my $ip = $2;
	    my $mac = $3;
	    my $iface = $4;
	    my $stuff = $5;

	    # this is not the interface you are looking for...
	    if ($diface ne $iface) {
		next;
	    }

	    if (exists($arpinfo{$ip})) {
		if ($arpinfo{$ip}{'mac'} ne $mac) {
		    print "os_getarpinfo: Conflicting arpinfo for $ip:\n";
		    print "    '$_'!?\n";
		    return 1;
		}
	    }
	    $arpinfo{$ip}{'name'} = $name;
	    $arpinfo{$ip}{'mac'} = $mac;
	    $arpinfo{$ip}{'iface'} = $iface;
	    if ($stuff =~ /permanent/) {
		$arpinfo{$ip}{'static'} = 1;
	    } else {
		$arpinfo{$ip}{'static'} = 0;
	    }
	}
    }
    close(ARP);

    %$airef = %arpinfo;
    return 0;
}

#
# Create a static ARP entry given info in the supplied hash.
# Returns zero on success, non-zero otherwise.
#
sub os_createarpentry($$$)
{
    my ($iface, $ip, $mac) = @_;

    return system("$ARP -s $ip $mac >/dev/null 2>&1");
}

sub os_removearpentry($;$)
{
    my ($iface, $ip) = @_;

    if (!defined($ip)) {
	return system("$ARP -i $iface -da >/dev/null 2>&1");
    }
    return system("$ARP -d $ip >/dev/null 2>&1");
}

#
# Returns whether static ARP is enabled or not in the passed param.
# Return zero on success, an error otherwise.
#
sub os_getstaticarp($$)
{
    my ($iface,$isenabled) = @_;

    my $info = `$IFCONFIGBIN $iface 2>/dev/null`;
    return $?
	if ($?);

    if ($info =~ /STATICARP/) {
	$$isenabled = 1;
    } else {
	$$isenabled = 0;
    }

    return 0;
}

#
# Turn on/off static ARP on the indicated interface.
# Return zero on success, an error otherwise.
#
sub os_setstaticarp($$)
{
    my ($iface,$enable) = @_;
    my $curenabled = 0;

    os_getstaticarp($iface, \$curenabled);
    if ($enable && !$curenabled) {
	return system("$IFCONFIGBIN $iface staticarp >/dev/null 2>&1");
    }
    if (!$enable && $curenabled) {
	return system("$IFCONFIGBIN $iface -staticarp >/dev/null 2>&1");
    }

    return 0;
}

#
# To find the block stores exported from a target portal:
#
#   iscontrol -d -t <storage-host>
#
# To use a remote iSCSI target, the info has to be in /etc/iscsi.conf:
#
#   <bsid> {
#     initiatorname = <our hostname>
#     targetname    = <iqn>
#     targetaddress = <storage-host>
#   }
#
# To login to a remote iSCSI target:
# 
#   iscontrol -c /etc/iscsi.conf -n <bsid>
# 
# The session ID for the resulting session can be determined from the
# sysctl net.iscsi_initiator info:
#
#   net.iscsi_initiator.<session>.targetname: <iqn>
#   net.iscsi_initiator.<session>.targeaddress: <storage-host-IP>
#
# To stop a session (logout) you must first determine its pid from
# the net.iscsi_initiator info:
#
#   net.iscsi_initiator.<session>.pid: <pid>
#
# and then send it a HUP:
#
#   kill -HUP <pid>
#
# Once a blockstore is added, it will appear as a /dev/da? device.
# I have not found a straight-forward way to map session to device.
# What we do now is to use the session ID to match up info from
# "camcontrol identify da<N> -v". camcontrol will return output like:
#
#   (pass3:iscsi0:0:0:0): ATAPI_IDENTIFY. ACB: ...
#   ...
#
# where N in "iscsiN" will be the session.
# 

sub iscsi_to_dev($)
{
    my ($session) = @_;

    #
    # XXX this is a total hack
    #
    my @lines = `ls /dev/da* 2>&1`;
    foreach (@lines) {
	if (m#^/dev/(da\d+)$#) {
	    my $dev = $1;
	    my $out = `camcontrol identify $dev -v 2>&1`;
	    if ($out =~ /^\(pass\d+:iscsi(\d+):/) {
		if ($1 == $session) {
		    return $dev;
		}
	    }
	}
    }

    return undef;
}

sub serial_to_dev($)
{
    my ($sn) = @_;

    #
    # XXX this is a total hack
    #
    if (! -x "$SMARTCTL") {
	return undef;
    }

    my @lines = `ls /dev/da* 2>&1`;
    foreach (@lines) {
	if (m#^/dev/(da\d+)$#) {
	    my $dev = $1;
	    my $out = `$SMARTCTL -i /dev/$dev 2>&1 | grep 'Serial Number'`;
	    if ($out =~ /^Serial Number:\s+$sn/) {
		return $dev;
	    }
	}
    }

    return undef;
}

sub uuid_to_session($)
{
    my ($uuid) = @_;

    my @lines = `sysctl net.iscsi_initiator 2>&1`;
    foreach (@lines) {
	if (/net\.iscsi_initiator\.(\d+)\.targetname: $uuid/) {
	    return $1;
	}
    }

    return undef;
}

sub uuid_to_daemonpid($)
{
    my ($uuid) = @_;
    my $session;

    my @lines = `sysctl net.iscsi_initiator 2>&1`;
    foreach (@lines) {
	if (/net\.iscsi_initiator\.(\d+)\.targetname: $uuid/) {
	    $session = $1;
	    next;
	}
	if (/net\.iscsi_initiator\.(\d+)\.pid: (\d+)/) {
	    if (defined($session) && $1 == $session) {
		return $2;
	    }
	}
    }

    return undef;
}

#
# Return the name (e.g., "da0") of the boot disk, aka the "system volume".
#
sub get_bootdisk()
{
    my $disk = undef;
    my $line = `$MOUNT | grep ' on / '`;

    if ($line && $line =~ /^\/dev\/(\S+)s1a on \//) {
	$disk = $1;
    }
    return $disk;
}

#
# We are relying on GEOM, so use its kernel info to tell us what
# the disks are.
#
sub get_geominfo()
{
    my %geominfo = ();

    my @lines = `sysctl -n kern.geom.conftxt`;
    chomp(@lines);
    if (@lines > 0) {
	# FBSD9 and above.
	foreach (@lines) {
	    next if ($_ eq "");
	    my @vals = split /\s/;

	    # assume 2k sector size means a CD drive
	    if ($vals[0] == 0 && $vals[1] eq "DISK" && $vals[4] == 2048) {
		next;
	    }

	    my $dev = $vals[2];
	    $geominfo{$dev}{'level'} = $vals[0];
	    $geominfo{$dev}{'type'} = $vals[1];
	    # size is in bytes, convert to MiB
	    $geominfo{$dev}{'size'} = int($vals[3] / 1024 / 1024);
	    if ($vals[1] eq "DISK") {
		$geominfo{$dev}{'inuse'} = 0;
	    }
	}
    } else {
	# FBSD8: no sysctl, have to parse geom output
	my ($curdev,$curpart,$skipping);

	# first find all the disks
	if (!open(FD, "geom disk list|")) {
	    warn("*** get_geominfo: could not execute geom command\n");
	    return undef;
	}
	while (<FD>) {
	    if (/^\d+\.\s+Name:\s+(\S+)$/) {
		$curdev = $1;
		$geominfo{$curdev}{'level'} = 0;
		$geominfo{$curdev}{'type'} = "DISK";
		$geominfo{$curdev}{'inuse'} = 0;
		next;
	    }
	    if (/\sMediasize:\s+(\d+)\s/) {
		if ($curdev) {
		    $geominfo{$curdev}{'size'} = int($1 / 1024 / 1024);
		    $curdev = undef;
		}
		next;
	    }
	    $curdev = undef;
	}
	close(FD);

	# now find all the partitions on those disks
	if (!open(FD, "geom part list|")) {
	    warn("*** get_geominfo: could not execute geom command\n");
	    return undef;
	}
	$skipping = 1;
	$curdev = $curpart = undef;
	while (<FD>) {
	    if (/^Geom name:\s+(\S+)/) {
		$curdev = $1;
		if (exists($geominfo{$curdev})) {
		    $skipping = 2;
		}
		next;
	    }
	    next if ($skipping < 2);

	    if (/^Providers:/) {
		$skipping = 3;
		next;
	    }
	    next if ($skipping < 3);

	    if (/^\d+\.\s+Name:\s+(\S+)$/) {
		$curpart = $1;
		$geominfo{$curpart}{'level'} = $geominfo{$curdev}{'level'} + 1;
		$geominfo{$curpart}{'type'} = "PART";
		next;
	    }
	    if (/\sMediasize:\s+(\d+)\s/) {
		$geominfo{$curpart}{'size'} = int($1 / 1024 / 1024);
		next;
	    }

	    if (/^Consumers:/) {
		$skipping = 1;
		next;
	    }
	}
	close(FD);

	# and finally, vinums
	if (!open(FD, "geom vinum list|")) {
	    warn("*** get_geominfo: could not execute geom command\n");
	    return undef;
	}
	$curpart = undef;
	$skipping = 1;
	while (<FD>) {
	    if (/^Providers:/) {
		$skipping = 2;
		next;
	    }
	    next if ($skipping < 2);

	    if (/^\d+\.\s+Name:\s+(\S+)$/) {
		$curpart = $1;
		$geominfo{$curpart}{'level'} = 2;
		$geominfo{$curpart}{'type'} = "VINUM";
		next;
	    }
	    if (/\sMediasize:\s+(\d+)\s/) {
		$geominfo{$curpart}{'size'} = int($1 / 1024 / 1024);
		next;
	    }

	    if (/^Consumers:/) {
		$skipping = 1;
		next;
	    }
	}
	close(FD);
    }

    #
    # Make a pass through and mark disks that are in use where "in use"
    # means "has a partition".
    #
    foreach my $dev (keys %geominfo) {
	if ($geominfo{$dev}{'type'} eq "PART" &&
	    $geominfo{$dev}{'level'} == 1 &&
	    $dev =~ /^(.*)s\d+$/) {
	    if (exists($geominfo{$1})) {
		$geominfo{$1}{'inuse'} = 1;
	    }
	}
    }

    return \%geominfo;
}

#
# Handle one-time operations.
# Return a cookie (object) with current state of storage subsystem.
#
sub os_init_storage($)
{
    my ($lref) = @_;
    my $gotlocal = 0;
    my $gotnonlocal = 0;
    my $gotelement = 0;
    my $gotslice = 0;
    my $gotiscsi = 0;
    my $needavol = 0;
    my $needall = 0;

    my %so = ();

    foreach my $href (@{$lref}) {
	if ($href->{'CMD'} eq "ELEMENT") {
	    $gotelement++;
	} elsif ($href->{'CMD'} eq "SLICE") {
	    $gotslice++;
	    if ($href->{'BSID'} eq "SYSVOL" ||
		$href->{'BSID'} eq "NONSYSVOL") {
		$needavol = 1;
	    } elsif ($href->{'BSID'} eq "ANY") {
		$needall = 1;
	    }
	}
	if ($href->{'CLASS'} eq "local") {
	    $gotlocal++;
	} else {
	    $gotnonlocal++;
	    if ($href->{'PROTO'} eq "iSCSI") {
		$gotiscsi++;
	    }
	}
    }

    # check for local storage incompatibility
    if ($needall && $needavol) {
	warn("*** storage: Incompatible local volumes.\n");
	return undef;
    }
	
    # initialize volume manage if needed for local slices
    if ($gotlocal && $gotslice) {
	#
	# gvinum: put module load in /boot/loader.conf so that /etc/fstab
	# mounts will work.
	#
	if (mysystem("grep -q 'geom_vinum_load=\"YES\"' /boot/loader.conf")) {
	    if (!open(FD, ">>/boot/loader.conf")) {
		warn("*** storage: could not enable gvinum in /boot/loader.conf\n");
		return undef;
	    }
	    print FD "# added by $BINDIR/rc/rc.storage\n";
	    print FD "geom_vinum_load=\"YES\"\n";
	    close(FD);

	    # and do a one-time start
	    mysystem("gvinum start");
	}

	#
	# Grab the bootdisk and current GEOM state
	#
	my $bdisk = get_bootdisk();
	my $ginfo = get_geominfo();
	if (!exists($ginfo->{$bdisk}) || $ginfo->{$bdisk}->{'inuse'} == 0) {
	    warn("*** storage: bootdisk '$bdisk' marked as not in use!?\n");
	    return undef;
	}
	$so{'BOOTDISK'} = $bdisk;
	$so{'GEOMINFO'} = $ginfo;
	if (0) {
	    print STDERR "BOOTDISK='$bdisk'\nGEOMINFO=\n";
	    foreach my $dev (keys %$ginfo) {
		my $type = $ginfo->{$dev}->{'type'};
		my $lev = $ginfo->{$dev}->{'level'};
		my $size = $ginfo->{$dev}->{'size'};
		print STDERR "name=$dev, type=$type, level=$lev, size=$size\n";
	    }
	    return undef;
	}
    }

    if ($gotiscsi) {
	my $redir = ">/dev/null 2>&1";

	if (! -x "$ISCSI") {
	    warn("*** storage: $ISCSI does not exist, cannot continue\n");
	    return undef;
	}

	#
	# XXX load initiator driver
	#
	if (mysystem("kldstat | grep -q iscsi_initiator") &&
	    mysystem("kldload iscsi_initiator.ko $redir")) {
	    warn("*** storage: Could not load iscsi_initiator kernel module\n");
	    return undef;
	}
    }

    $so{'INITIALIZED'} = 1;
    return \%so;
}

#
# os_check_storage(sobject,confighash)
#
#   Determines if the storage unit described by confighash exists and
#   is properly configured. Returns zero if it doesn't exist, 1 if it
#   exists and is correct, -1 otherwise.
#
#   Side-effect: Creates the hash member $href->{'LNAME'} with the /dev
#   name of the storage unit.
#
sub os_check_storage($$)
{
    my ($so,$href) = @_;

    if ($href->{'CMD'} eq "ELEMENT") {
	return os_check_storage_element($so,$href);
    }
    if ($href->{'CMD'} eq "SLICE") {
	return os_check_storage_slice($so,$href);
    }
    return -1;
}

sub os_check_storage_element($$)
{
    my ($so,$href) = @_;
    my $CANDISCOVER = 0;
    #my $redir = "";
    my $redir = ">/dev/null 2>&1";

    #
    # iSCSI:
    #  make sure iscsi_initiator kernel module is loaded
    #  make sure the IQN exists
    #  make sure there is an entry in /etc/iscsi.conf.
    #
    if ($href->{'CLASS'} eq "SAN" && $href->{'PROTO'} eq "iSCSI") {
	my $hostip = $href->{'HOSTIP'};
	my $uuid = $href->{'UUID'};
	my $bsid = $href->{'VOLNAME'};
	my @lines;
	my $cmd;

	#
	# See if the block store exists on the indicated server.
	# If not, something is very wrong, return -1.
	#
	# Note that the server may not support discovery. If not, we don't
	# do it since it is only a sanity check anyway.
	#
	if ($CANDISCOVER) {
	    @lines = `$ISCSI -d -t $hostip 2>&1`;
	    if ($? != 0) {
		warn("*** could not find exported iSCSI block stores\n");
		return -1;
	    }
	    my $taddr = "";
	    for (my $i = 0; $i < scalar(@lines); $i++) {
		# found target, look at next
		if ($lines[$i] =~ /^TargetName=$uuid/ &&
		    $lines[$i+1] =~ /^TargetAddress=($hostip.*)/) {
		    $taddr = $1;
		    last;
		}
	    }
	    if (!$taddr) {
		warn("*** could not find iSCSI block store '$uuid'\n");
		return -1;
	    }
	}

	#
	# See if it is in the config file.
	# If not, we have not done the one-time initialization, return 0.
	#
	if (! -r "$ISCSICNF" || mysystem("grep -q '$uuid' $ISCSICNF")) {
	    return 0;
	}

	#
	# XXX hmm...FreeBSD does not have an /etc/rc.d script for starting
	# up iscontrol instances. So we have to do it everytime right now.
	#
	# First, check and see if there is a session active for this
	# blockstore. If not we must start one.
	#
	my $session = uuid_to_session($uuid);
	if (!defined($session)) {
	    if (mysystem("$ISCSI -c $ISCSICNF -n $bsid $redir")) {
		warn("*** $bsid: could not create iSCSI session\n");
		return -1;
	    }
	    sleep(1);
	    $session = uuid_to_session($uuid);
	}

	#
	# Figure out the device name from the session and report all is good.
	#
	my $dev = iscsi_to_dev($session);
	if (defined($dev)) {
	    $href->{'LNAME'} = $dev;
	    return 1;
	}

	#
	# Otherwise, we are in some indeterminite state, return -1.
	#
	warn("*** $bsid: found iSCSI session but could not determine local device\n");
	return -1;
    }

    #
    # local disk:
    #  make sure disk exists
    #
    if ($href->{'CLASS'} eq "local") {
	my $bsid = $href->{'VOLNAME'};
	my $sn = $href->{'UUID'};

	my $dev = serial_to_dev($sn);
	if (defined($dev)) {
	    $href->{'LNAME'} = $dev;
	    return 1;
	}

	# for physical disks, there is no way to "create" it so return error
	warn("*** $bsid: could not find HD with serial '$sn'\n");
	return -1;
    }

    warn("*** $bsid: unsupported class/proto '" .
	 $href->{'CLASS'} . "/" . $href->{'PROTO'} . "'\n");
    return -1;
}

#
# Return 0 if does not exist
# Return 1 if exists and correct
# Return -1 otherwise
#
sub os_check_storage_slice($$)
{
    my ($so,$href) = @_;
    my $bsid = $href->{'BSID'};

    #
    # local storage:
    #  if BSID==SYSVOL:
    #    see if 4th part of boot disk exists (eg: da0s4) and
    #    is of type freebsd
    #  else if BSID==NONSYSVOL:
    #    see if there is a concat volume with appropriate name
    #  else if BSID==ANY:
    #    see if there is a concat volume with appropriate name
    #  if there is a mountpoint, see if it exists in /etc/fstab
    #
    # List all volumes:
    #   gvinum lv
    #
    #
    if ($href->{'CLASS'} eq "local") {
	my $lv = $href->{'VOLNAME'};
	my ($dev, $devtype, $mdev);

	my $ginfo = $so->{'GEOMINFO'};
	my $bdisk = $so->{'BOOTDISK'};

	# figure out the device of interest
	if ($bsid eq "SYSVOL") {
	    $dev = "${bdisk}s4";
	    $mdev = "${dev}a";
	    $devtype = "PART";
	} else {
	    $dev = $mdev = "gvinum/$lv";
	    $devtype = "VINUM";
	}
	my $devsize = $href->{'VOLSIZE'};

	# if the device does not exist, return 0
	if (!exists($ginfo->{$dev})) {
	    return 0;
	}
	# if it exists but is of the wrong type, we have a problem!
	my $atype = $ginfo->{$dev}->{'type'};
	if ($atype ne $devtype) {
	    warn("*** $lv: actual type ($atype) != expected type ($devtype)\n");
	    return -1;
	}
	# ditto for size, unless this is the SYSVOL where we ignore user size
	my $asize = $ginfo->{$dev}->{'size'};
	if ($bsid ne "SYSVOL" && $asize != $devsize) {
	    warn("*** $lv: actual size ($asize) != expected size ($devsize)\n");
	    return -1;
	}

	# if there is a mountpoint, make sure it is mounted
	my $mpoint = $href->{'MOUNTPOINT'};
	if ($mpoint) {
	    my $line = `$MOUNT | grep '^/dev/$mdev on '`;
	    if (!$line) {
		warn("*** $lv: is not mounted, should be on $mpoint\n");
		return -1;
	    }
	    if ($line !~ /^\/dev\/$mdev on (\S+) / || $1 ne $mpoint) {
		warn("*** $lv: mounted on $1, should be on $mpoint\n");
		return -1;
	    }
	}

	$href->{'LNAME'} = $mdev;
	return 1;
    }

    warn("*** $bsid: unsupported class '" . $href->{'CLASS'} . "'\n");
    return -1;
}

#
# os_create_storage(confighash)
#
#   Create the storage unit described by confighash. Unit must not exist
#   (os_check_storage should be called first to verify). Return one on
#   success, zero otherwise.
#
sub os_create_storage($$)
{
    my ($so,$href) = @_;

    if ($href->{'CMD'} eq "ELEMENT") {
	return os_create_storage_element($so, $href);
    }
    if ($href->{'CMD'} eq "SLICE") {
	return os_create_storage_slice($so, $href);
    }
    return 0;
}

sub os_create_storage_element($$)
{
    my ($so,$href) = @_;
    #my $redir = "";
    my $redir = ">/dev/null 2>&1";

    if ($href->{'CLASS'} eq "SAN" && $href->{'PROTO'} eq "iSCSI") {
	my $hostip = $href->{'HOSTIP'};
	my $uuid = $href->{'UUID'};
	my $bsid = $href->{'VOLNAME'};
	my $cmd;

	#
	# Handle one-time setup of /etc/iscsi.conf.
	#
	if (! -r "$ISCSICNF" || mysystem("grep -q '$uuid' $ISCSICNF $redir")) {
	    if (!open(FD, ">>$ISCSICNF")) {
		warn("*** could not update $ISCSICNF\n");
		return 0;
	    }
	    my $hname = `hostname`;
	    chomp($hname);
	    print FD <<EOF;
$bsid {
    initiatorname = $hname
    targetname    = $uuid
    targetaddress = $hostip
}
EOF
	    close(FD);   
	} else {
	    warn("*** $bsid: trying to create but already exists!?\n");
	    return 0;
        }

	#
	# Everything has been setup, start the daemon.
	#
	if (mysystem("$ISCSI -c $ISCSICNF -n $bsid $redir")) {
	    warn("*** $bsid: could not create iSCSI session\n");
	    return 0;
	}
	sleep(1);

	#
	# Find the session ID and device name.
	#
	my $session = uuid_to_session($uuid);
	if (!defined($session)) {
	    warn("*** $bsid: could not find iSCSI session\n");
	    return 0;
	}
	my $dev = iscsi_to_dev($session);
	if (!defined($dev)) {
	    warn("*** $bsid: could not map iSCSI session to device\n");
	    return 0;
	}

	$href->{'LNAME'} = $dev;
	return 1;
    }

    warn("*** Only support SAN/iSCSI now\n");
    return 0;
}

sub os_create_storage_slice($$)
{
    my ($so,$href) = @_;
    my $bsid = $href->{'BSID'};

    #
    # local storage:
    #  if BSID==SYSVOL:
    #     create the 4th part of boot disk with type freebsd,
    #	  create a native filesystem (that imagezip would understand).
    #  else if BSID==NONSYSVOL:
    #	  make sure partition 1 exists on all disks and each has type
    #	  freebsd, create concat volume with appropriate name
    #  else if BSID==ANY:
    #	  make sure all partitions exist (4 on sysvol, 1 on all others)
    #     and have type freebsd, create a concat volume with appropriate
    #	  name across all available disks
    #  if there is a mountpoint:
    #     create a filesystem on device, mount it, add to /etc/fstab
    #
    if ($href->{'CLASS'} eq "local") {
	my $lv = $href->{'VOLNAME'};
	my $lvsize = $href->{'VOLSIZE'};
	my $mdev = "";

	my $bdisk = $so->{'BOOTDISK'};
	my $ginfo = $so->{'GEOMINFO'};

	# record all the output for debugging
	my $log = "/var/emulab/logs/$lv.out";
	my $redir = ">>$log 2>&1";
	my $logmsg = ", see $log";
	mysystem("cp /dev/null $log");

	#
	# System volume:
	#
	# gpart add -i 4 -t freebsd da0
	# gpart create -s BSD da0s4
	# gpart add -t freebsd-ufs da0s4
	#
	if ($bsid eq "SYSVOL") {
	    my $slice = "$bdisk" . "s4";
	    my $part = "$slice" . "a";

	    if (mysystem("gpart add -i 4 -t freebsd $bdisk $redir")) {
		warn("*** $lv: could not create $slice$logmsg\n");
		return 0;
	    }
	    if (mysystem("gpart create -s BSD $slice $redir") ||
		mysystem("gpart add -t freebsd-ufs $slice $redir")) {
		warn("*** $lv: could not create $part$logmsg\n");
		return 0;
	    }
	    $mdev = $part;
	}

	#
	# Non-system volume or all space.
	# If partitions have not yet been initialized handle that:
	#
	# gpart add -i 4 -t freebsd da0	(ANY only)
	# gpart create -s mbr da1
	# gpart add -i 1 -t freebsd da1
	#
	else {
	    if (!exists($so->{'VINUM_SPACEMAP'})) {
		my %spacemap = ();

		if ($bsid eq "ANY") {
		    $spacemap{$bdisk}{'pnum'} = 4;
		}
		foreach my $dev (keys %$ginfo) {
		    if ($ginfo->{$dev}->{'type'} eq "DISK" &&
			$ginfo->{$dev}->{'inuse'} == 0) {
			$spacemap{$dev}{'pnum'} = 0;
		    }
		}
		if (keys(%spacemap) == 0) {
		    warn("*** $lv: no space found\n");
		    return 0;
		}

		#
		# Create partitions on each disk
		#
		foreach my $disk (keys %spacemap) {
		    my $pnum = $spacemap{$disk}{'pnum'};

		    #
		    # If pnum==0, we need an MBR first
		    #
		    if ($pnum == 0) {
			if (mysystem("gpart create -s mbr $disk $redir")) {
			    warn("*** $lv: could not create MBR on $disk$logmsg\n");
			    return 0;
			}
			$pnum = $spacemap{$disk}{'pnum'} = 1;
		    }
		    if (mysystem("gpart add -i $pnum -t freebsd $disk $redir")) {
			warn("*** $lv: could not create ${disk}s${pnum}$logmsg\n");
			return 0;
		    }
		}

		#
		# Refresh GEOM info and see how much space is available on
		# our disk partitions.
		# XXX we allow some time for changes to take effect.
		#
		sleep(1);
		$ginfo = $so->{'GEOMINFO'} = get_geominfo();

		my $total_size = 0;
		foreach my $disk (keys %spacemap) {
		    my $part = $disk . "s" . $spacemap{$disk}{'pnum'};
		    if (!exists($ginfo->{$part}) ||
			$ginfo->{$part}->{'type'} ne "PART") {
			warn("*** $lv: created partitions are wrong!?\n");
			return 0;
		    }
		    $spacemap{$disk}{'size'} = $ginfo->{$part}->{'size'};
		    $total_size += $spacemap{$disk}{'size'};
		}

		$so->{'VINUM_SPACE'} = $total_size;
		$so->{'VINUM_SPACEMAP'} = \%spacemap;
	    }

	    #
	    # Now create a gvinum for the volume using the available space:
	    #
	    # cat > /tmp/h2d2.conf
	    # drive vinum_da0s4 device /dev/da0s4 (ANY only)
	    # drive vinum_da1s1 device /dev/da1s1
	    # volume h2d2
	    #   plex org concat
	    #     sd length NNNm drive vinum_da0s4 (ANY only)
	    #     sd length NNNm drive vinum_da1s1
	    #
	    # gvinum create /tmp/h2d2.conf
	    # newfs /dev/gvinum/h2d2
	    #
	    my $space = $so->{'VINUM_SPACEMAP'};
	    my $total_size = $so->{'VINUM_SPACE'};

	    #
	    # Figure out how much space to take from each disk for this
	    # volume. We take proportionally from each.
	    #
	    my $vsize = $lvsize;
	    foreach my $disk (keys %$space) {
		my $frac = $space->{$disk}->{'size'} / $total_size;
		$space->{$disk}->{'vsize'} = int($lvsize * $frac);
		$vsize -= $space->{$disk}->{'vsize'};
	    }

	    #
	    # Create a gvinum config file to concatonate drive space.
	    # XXX should stripe if practical.
	    #
	    my $cfile = "/tmp/$lv.conf";
	    unlink($cfile);
	    if (!open(FD, ">$cfile")) {
		warn("*** $lv: could not create gvinum config\n");
		return 0;
	    }
	    if (!exists($so->{'VINUM_SUBDISKS'})) {
		foreach my $disk (keys %$space) {
		    my $pdev = $disk . "s" . $space->{$disk}->{'pnum'};
		    print FD "drive vinum_$pdev device /dev/$pdev\n";
		}
	    }
	    print FD "volume $lv\n";
	    print FD "  plex org concat\n";
	    foreach my $disk (keys %$space) {
		my $pdev = $disk . "s" . $space->{$disk}->{'pnum'};
		my $sdsize = $space->{$disk}->{'vsize'};
		if ($vsize > 0) {
#		    warn("*** $lv: taking extra ${vsize}MiB from $pdev\n");
		    $sdsize += $vsize;
		    $vsize = 0;
		}
		print FD "    sd length ${sdsize}m drive vinum_$pdev\n";
	    }
	    close(FD);

	    # create the vinum
	    if (mysystem("gvinum create $cfile $redir")) {
		warn("*** $lv: could not create vinum$logmsg\n");
#		unlink($cfile);
		return 0;
	    }
	    unlink($cfile);

	    # subdisks exist at this point
	    $so->{'VINUM_SUBDISKS'} = 1;

	    # XXX need some delay before accessing device?
	    sleep(1);

	    $mdev = "gvinum/$lv";
	}

	#
	# Update the geom info to reflect new devices
	#
	$ginfo = $so->{'GEOMINFO'} = get_geominfo();
	if (!exists($ginfo->{$mdev})) {
	    warn("*** $lv: blockstore did not get created!?\n");
	    return 0;
	}

	#
	# Create the filesystem
	#
	if (mysystem("newfs /dev/$mdev $redir")) {
	    warn("*** $lv: could not create FS$logmsg\n");
	    return 0;
	}
	$href->{'LNAME'} = $mdev;

	#
	# Handle optional mounting
	#
	if (exists($href->{'MOUNTPOINT'})) {
	    my $mpoint = $href->{'MOUNTPOINT'};

	    if (! -d "$mpoint" && mysystem("$MKDIR -p $mpoint")) {
		warn("*** $lv: could not create mountpoint '$mpoint'\n");
		return 0;
	    }

	    if (!open(FD, ">>/etc/fstab")) {
		warn("*** $lv: could not add mount to /etc/fstab\n");
		return 0;
	    }
	    print FD "/dev/$mdev\t$mpoint\tufs\trw\t2\t2\n";
	    close(FD);

	    if (mysystem("mount $mpoint $redir")) {
		warn("*** $lv: could not mount on $mpoint$logmsg\n");
		return 0;
	    }
	}

	return 1;
    }

    warn("*** $bsid: unsupported class '" . $href->{'CLASS'} . "'\n");
    return 0;
}

sub os_remove_storage($$$)
{
    my ($so,$href,$teardown) = @_;

    if ($href->{'CMD'} eq "ELEMENT") {
	return os_remove_storage_element($so, $href, $teardown);
    }
    if ($href->{'CMD'} eq "SLICE") {
	return os_remove_storage_slice($so, $href, $teardown);
    }
    return 0;
}

sub os_remove_storage_element($$$)
{
    my ($so,$href,$teardown) = @_;
    #my $redir = "";
    my $redir = ">/dev/null 2>&1";

    if ($href->{'CLASS'} eq "SAN" && $href->{'PROTO'} eq "iSCSI") {
	my $uuid = $href->{'UUID'};
	my $bsid = $href->{'VOLNAME'};

	#
	# Find the daemon instance and HUP it.
	# XXX continue even if we could not kill it.
	#
	my $pid = uuid_to_daemonpid($uuid);
	if (defined($pid)) {
	    if (mysystem("kill -HUP $pid $redir")) {
		warn("*** $bsid: could not kill $ISCSI daemon\n");
	    }
	}

	#
	# Remove /etc/iscsi.conf entry for block store
	#
	if ($teardown && !mysystem("grep -q '$uuid' $ISCSICNF $redir")) {
	    if (open(OFD, "<$ISCSICNF") && open(NFD, ">$ISCSICNF.new")) {
		# parser!? we don't need no stinkin parser...
		my $inentry = 0;
		while (<OFD>) {
		    if (/^$bsid {/) {
			$inentry = 1;
			next;
		    }
		    if ($inentry && /^}/) {
			$inentry = 0;
			next;
		    }
		    if (!$inentry) {
			print NFD $_;
		    }
		}
		close(OFD);
		close(NFD);
		if (mysystem("mv -f $ISCSICNF.new $ISCSICNF")) {
		    warn("*** $bsid: could not update $ISCSICNF\n");
		    return 0;
		}
	    }
	}
	return 1;
    }

    #
    # Nothing to do (yet) for a local disk
    #
    if ($href->{'CLASS'} eq "local") {
	return 1;
    }

    warn("*** Only support SAN/iSCSI now\n");
    return 0;
}

#
# teardown==0 means we are rebooting: unmount and shutdown gvinum
# teardown==1 means we are reconfiguring and will be destroying everything
#
sub os_remove_storage_slice($$$)
{
    my ($so,$href,$teardown) = @_;

    #
    # local storage:
    #  if BSID==ANY, see if there is a volume with appropriate name
    #  if BSID==SYSVOL, see if 4th part of boot disk exists (eg: da0s4)
    #  if BSID==NONSYSVOL, see if 1st part of 2nd disk exists (eg: da1s1)
    #  if there is a mountpoint, see if it exists in /etc/fstab
    #
    if ($href->{'CLASS'} eq "local") {
	my $bsid = $href->{'BSID'};
	my $lv = $href->{'VOLNAME'};

	my $ginfo = $so->{'GEOMINFO'};
	my $bdisk = $so->{'BOOTDISK'};

	# figure out the device of interest
	my ($dev, $devtype);
	if ($bsid eq "SYSVOL") {
	    $dev = "${bdisk}s4a";
	    $devtype = "PART";
	} else {
	    $dev = "gvinum/$lv";
	    $devtype = "VINUM";
	}

	# if the device does not exist, we have a problem!
	if (!exists($ginfo->{$dev})) {
	    warn("*** $lv: device '$dev' does not exist\n");
	    return 0;
	}
	# ditto if it exists but is of the wrong type
	my $atype = $ginfo->{$dev}->{'type'};
	if ($atype ne $devtype) {
	    warn("*** $lv: actual type ($atype) != expected type ($devtype)\n");
	    return 0;
	}

	# record all the output for debugging
	my $log = "/var/emulab/logs/$lv.out";
	my $redir = ">>$log 2>&1";
	my $logmsg = ", see $log";
	mysystem("cp /dev/null $log");

	#
	# Unmount and remove mount info from fstab.
	#
	# On errors, we warn but don't stop. We do everything in our
	# power to take things down.
	#
	if (exists($href->{'MOUNTPOINT'})) {
	    my $mpoint = $href->{'MOUNTPOINT'};

	    if (mysystem("umount $mpoint")) {
		warn("*** $lv: could not unmount $mpoint\n");
	    }

	    if ($teardown) {
		my $tdev = "/dev/$dev";
		$tdev =~ s/\//\\\//g;
		if (mysystem("sed -E -i -e '/^$tdev/d' /etc/fstab")) {
		    warn("*** $lv: could not remove mount from /etc/fstab\n");
		}
	    }
	}

	#
	# Remove LV
	#
	if ($teardown) {
	    #
	    # System volume:
	    #
	    # gpart destroy -F da0s4
	    # gpart delete -i 4 da0
	    #
	    if ($bsid eq "SYSVOL") {
		my $slice = "$bdisk" . "s4";

		if (mysystem("gpart destroy -F $slice $redir")) {
		    warn("*** $lv: could not destroy ${slice}a$logmsg\n");
		}
		if (mysystem("gpart delete -i 4 $bdisk $redir")) {
		    warn("*** $lv: could not destroy $slice$logmsg\n");
		}
		return 1;
	    }

	    #
	    # Other, gvinum volume:
	    #
	    #   gvinum rm -r h2d2
	    #
	    if (mysystem("gvinum rm -r $lv $redir")) {
		warn("*** $lv: could not destroy$logmsg\n");
	    }

	    #
	    # If no volumes left:
	    #
	    #   gvinum rm -r vinum_da0s4 (ANY only)
	    #   gvinum rm -r vinum_da1s1
	    #
	    #   gpart delete -i 4 da0 (ANY only)
	    #   gpart destroy -F da1
	    #
	    my $line = `gvinum lv | grep 'volumes:'`;
	    chomp($line);
	    if (!$line || $line !~ /^0 volumes:/) {
		return 1;
	    }

	    if (!open(FD, "gvinum ld|")) {
		warn("*** $lv: could not find subdisks$logmsg\n");
		return 1;
	    }

	    while (<FD>) {
		if (/^D vinum_(\S+)/) {
		    my $slice = $1;

		    if (mysystem("gvinum rm vinum_$slice $redir")) {
			warn("*** $lv: could not destroy subdisk vinum_$slice$logmsg\n");
		    }
		    if ($slice eq "${bdisk}s4") {
			if (mysystem("gpart delete -i 4 $bdisk $redir")) {
			    warn("*** $lv: could not destroy $slice$logmsg\n");
			}
		    } elsif ($slice =~ /^(.*)s1$/) {
			my $disk = $1;
			if ($disk eq $bdisk ||
			    mysystem("gpart destroy -F $disk $redir")) {
			    warn("*** $lv: could not destroy $slice$logmsg\n");
			}
		    }
		}
	    }
	    close(FD);

	    if (mysystem("gvinum stop $redir")) {
		warn("*** $lv: could not stop gvinum$logmsg\n");
	    }
	    if (mysystem("sed -i -e '/^# added by.*rc.storage/,+1d' /boot/loader.conf")) {
		warn("*** $lv: could not remove vinum load from /boot/loader.conf\n");
	    }
	}

	return 1;
    }

    return 0;
}

sub mysystem($)
{
    my ($cmd) = @_;
    if (0) {
	print STDERR "CMD: $cmd\n";
    }
    return system($cmd);
}

sub mybacktick($)
{
    my ($cmd) = @_;
    if (0) {
	print STDERR "CMD: $cmd\n";
    }
    return `$cmd`;
}

1;
