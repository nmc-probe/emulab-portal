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
# Miscellaneous OS-independent utility routines.
#

package libutil;
use Exporter;
@ISA    = "Exporter";
@EXPORT = qw( ipToMac macAddSep fatal mysystem mysystem2
              findDNS setState isRoutable findDomain
            );

use libtmcc;
use Socket;

sub setState($) {
    my ($state) = @_;

    libtmcc::tmcc(TMCCCMD_STATE(),"$state");
}

sub ipToMac($) {
    my $ip = shift;

    return sprintf("0000%02x%02x%02x%02x",$1,$2,$3,$4)
	if ($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);

    return undef;
}

sub macAddSep($;$) {
    my ($mac,$sep) = @_;
    if (!defined($sep)) {
	$sep = ":";
    }

    return "$1$sep$2$sep$3$sep$4$sep$5$sep$6"
	if ($mac =~ /^([0-9a-zA-Z]{2})([0-9a-zA-Z]{2})([0-9a-zA-Z]{2})([0-9a-zA-Z]{2})([0-9a-zA-Z]{2})([0-9a-zA-Z]{2})$/);

    return undef;
}

#
# Is an IP routable?
#
sub isRoutable($)
{
    my ($IP)  = @_;
    my ($a,$b,$c,$d) = ($IP =~ /^(\d*)\.(\d*)\.(\d*)\.(\d*)/);

    #
    # These are unroutable:
    # 10.0.0.0        -   10.255.255.255  (10/8 prefix)
    # 172.16.0.0      -   172.31.255.255  (172.16/12 prefix)
    # 192.168.0.0     -   192.168.255.255 (192.168/16 prefix)
    #

    # Easy tests.
    return 0
	if (($a eq "10") ||
	    ($a eq "192" && $b eq "168"));

    # Lastly
    return 0
	if (inet_ntoa((inet_aton($IP) & inet_aton("255.240.0.0"))) eq
	    "172.16.0.0");

    return 1;
}

#
# XXX boss is the DNS server for everyone
#
sub findDNS($)
{
    my ($ip) = @_;

    my ($bossname,$bossip) = libtmcc::tmccbossinfo();
    if ($bossip =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
	$bossip = $1;
    } else {
	return undef;
	# die "Could not find boss IP address (tmccbossinfo failed?)";
    }

    return $bossip;
}

#
# Get our domain
#
sub findDomain()
{
    import emulabpaths;

    return undef
	if (! -e "$BOOTDIR/mydomain");
    
    my $domain = `cat $BOOTDIR/mydomain`;
    chomp($domain);
    return $domain;
}

#
# Print error and exit.
#
sub fatal($)
{
    my ($msg) = @_;

    die("*** $0:\n".
	"    $msg\n");
}

#
# Run a command string, redirecting output to a logfile.
#
sub mysystem($)
{
    my ($command) = @_;

    if (1) {
	print STDERR "mysystem: '$command'\n";
    }

    system($command);
    if ($?) {
	fatal("Command failed: $? - $command");
    }
}
sub mysystem2($)
{
    my ($command) = @_;

    if (1) {
	print STDERR "mysystem: '$command'\n";
    }

    system($command);
    if ($?) {
	print STDERR "Command failed: $? - '$command'\n";
    }
}

# Must be last thing in file.
1;
