#!/usr/bin/perl -wT

#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2006 University of Utah and the Flux Group.
# All rights reserved.
#

#
# FreeBSD specific routines and constants for the client bootime setup stuff.
#
package liblocsetup;
use Exporter;
@ISA = "Exporter";
@EXPORT =
    qw ( $CP $EGREP $NFSMOUNT $UMOUNT $TMPASSWD $SFSSD $SFSCD $RPMCMD $HOSTSFILE
	 $LOOPBACKMOUNT 
	 os_account_cleanup os_ifconfig_line os_etchosts_line
	 os_setup os_groupadd os_useradd os_userdel os_usermod os_mkdir
	 os_ifconfig_veth
	 os_routing_enable_forward os_routing_enable_gated
	 os_routing_add_manual os_routing_del_manual os_homedirdel
	 os_groupdel os_getnfsmounts
	 os_fwconfig_line os_fwrouteconfig_line
       );

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
sub MFS()	{ return libsetup::MFS(); }
sub JAILED()	{ return libsetup::JAILED(); }

#
# Various programs and things specific to FreeBSD and that we want to export.
# 
$CP		= "/bin/cp";
$EGREP		= "/usr/bin/egrep -s -q";
$NFSMOUNT	= "/sbin/mount -o -b ";
$LOOPBACKMOUNT	= "/sbin/mount -t null ";
$UMOUNT		= "/sbin/umount";
$TMPASSWD	= "$ETCDIR/master.passwd";
$SFSSD		= "/usr/local/sbin/sfssd";
$SFSCD		= "/usr/local/sbin/sfscd";
$RPMCMD		= "/usr/local/bin/rpm";
$HOSTSFILE	= "/etc/hosts";

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
my $IFALIAS     = "$IFCONFIGBIN %s alias %s netmask 0xffffff00";
my $IFC_1000MBS = "media 1000baseTX";
my $IFC_100MBS  = "media 100baseTX";
my $IFC_10MBS   = "media 10baseT/UTP";
my $IFC_FDUPLEX = "mediaopt full-duplex";
my $MKDIR	= "/bin/mkdir";
my $GATED	= "/usr/local/sbin/gated";
my $ROUTE	= "/sbin/route";
my $SHELLS	= "/etc/shells";
my $DEFSHELL	= "/bin/tcsh";

#
# OS dependent part of account cleanup. On a remote node, this will
# only be called from inside a JAIL, or from the prepare script. 
# 
sub os_account_cleanup()
{
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
sub os_ifconfig_line($$$$$$$;$$)
{
    my ($iface, $inet, $mask, $speed, $duplex, $aliases,
	$iface_type, $settings, $rtabid) = @_;
    my $media    = "";
    my $mediaopt = "";
    my ($uplines, $downlines);

    #
    # Need to check units on the speed. Just in case.
    #
    if ($speed =~ /(\d*)([A-Za-z]*)/) {
	if ($2 eq "Mbps") {
	    $speed = $1;
	}
	elsif ($2 eq "Kbps") {
	    $speed = $1 / 1000;
	}
	else {
	    warn("*** Bad speed units in ifconfig!\n");
	    $speed = 100;
	}
	if ($speed == 1000) {
	    $media = $IFC_1000MBS;
	}
	elsif ($speed == 100) {
	    $media = $IFC_100MBS;
	}
	elsif ($speed == 10) {
	    $media = $IFC_10MBS;
	}
	else {
	    warn("*** Bad Speed in ifconfig!\n");
	    $media = $IFC_100MBS;
	}
    }

    if ($duplex eq "full") {
	$mediaopt = $IFC_FDUPLEX;
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
	$uplines   .= sprintf($IFCONFIG, $iface, $inet, $mask, $media,$mediaopt);
	$downlines  = "$IFCONFIGBIN $iface down\n";
	
	if ($aliases ne "") {
	    # Must do this first to avoid lo0 routes.
	    $uplines .= "\n    ".
		"sysctl net.link.ether.inet.useloopback=0\n";

	    foreach my $alias (split(',', $aliases)) {
		my $ifalias = sprintf($IFALIAS, $iface, $alias);

		$uplines   .= "$ifalias\n";
		$downlines .= "$IFCONFIGBIN $iface -alias $alias\n";
	    }
	}
    }
    return ($uplines, $downlines);
}

#
# Specialized function for configing locally hacked veth devices.
#
sub os_ifconfig_veth($$$$$;$$$)
{
    my ($iface, $inet, $mask, $id, $vmac, $rtabid, $encap, $vtag) = @_;
    my ($uplines, $downlines);

    #
    # Do not try this on the MFS!
    #
    return ""
	if (MFS());

    require Socket;
    import Socket;

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

    #
    # Must set route table id before assigning IP address so that interface
    # route winds up in the correct table.
    #
    if (defined($rtabid)) {
	$uplines .= "$IFCONFIGBIN veth${id} rtabid $rtabid\n    ";
    }

    $uplines  .= "$IFCONFIGBIN veth${id} inet $inet netmask $mask";

    #
    # link1 on the veth device implies no encapsulation
    #
    if (!$encap) {
	$uplines .= " link1";
    }

    $downlines = "$IFCONFIGBIN veth${id} down\n    ".
	         "$IFCONFIGBIN veth${id} destroy";
    return ($uplines, $downlines);
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
    if (REMOTE() || MFS()) {
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

    if (REMOTE()) {
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

    if (REMOTE()) {
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
    if (! open(MOUNT, "/sbin/mount|")) {
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

    # XXX debugging
    my $logaccept = defined($fwinfo->{LOGACCEPT}) ? $fwinfo->{LOGACCEPT} : 0;
    my $logreject = defined($fwinfo->{LOGREJECT}) ? $fwinfo->{LOGREJECT} : 0;

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
	# Setup proxy ARP entries
	#
	if (defined($fwinfo->{MACS})) {
	    $upline .= "    sysctl net.link.ether.inet.proxygwonly=1\n";

	    # XXX must have an IP on the vlan dev for the arp to work
	    $upline .= "    ifconfig $vlandev inet 10.0.0.1 netmask 255.255.255.255\n";

	    # provide GW MAC to inside
	    $upline .= "    arp -i $vlandev -s " .
		$fwinfo->{GWIP} . " " . $fwinfo->{GWMAC} . " pub only\n";

	    # provide node MACs to outside
	    my $href = $fwinfo->{MACS};
	    while (my ($node,$mac) = each %$href) {
		$upline .= "    arp -i $pdev -s $node $mac pub only\n";
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
	if ($logaccept || $logreject) {
	    $downline .= "    sysctl net.inet.ip.fw.verbose=0\n";
	}
	$downline .= "    ipfw -q flush\n";
	$downline .= "    sysctl net.link.ether.bridge_cfg=\"\"\n";
	$downline .= "    sysctl net.link.ether.bridge_ipfw=0\n";
	$downline .= "    sysctl net.link.ether.bridge_vlan=1\n";
	if (defined($fwinfo->{MACS})) {
	    $downline .= "    arp -i $vlandev -d " . $fwinfo->{GWIP} . " pub\n";

	    my $href = $fwinfo->{MACS};
	    while (my ($node,$mac) = each %$href) {
		$downline .= "    arp -i $pdev -d $node pub\n";
	    }
	    $downline .= "    sysctl net.link.ether.inet.proxygwonly=0\n";
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

1;
