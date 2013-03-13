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
# Emulab wrapper class for the IP range buddy allocator.  Handles all of the
# Emulab-specific goo around allocating address ranges.
#
package IPBuddyWrapper;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw ( );

use English;
use emdb;
use libtblog_simple;
use VirtExperiment;
use IPBuddyAlloc;
use Socket;

# Constants

# Prototypes


#
# Create a new IPBuddyAlloc wrapper object.  Pass in a string specifying
# the type of address reservations to target.
#
sub new($$) {
    my ($class, $type) = @_;
    my $self = {};

    return undef
	unless defined($type);

    # Get the address range corresponding to this type from the database.
    # Currently we only support one range per type.
    my $qres =
	DBQueryWarn("select * from address_ranges where type='$type'");
    return undef
	if (!$qres);
    if ($qres->numrows() != 1) {
	tberror("More than one range entry found for this address ".
		"type in the DB: $type\n");
	return undef;
    }

    my ($baseaddr, $prefix, $type, $role) = $qres->fetchrow();

    # IPBuddyAlloc throws exceptions.
    my $buddy = eval { IPBuddyAlloc->New("$baseaddr/$prefix") };
    if ($@) {
	tberror("Could not allocate a new IP Buddy Allocator object: $@\n");
	return undef;
    }

    $self->{'BUDDY'} = $buddy;
    $self->{'ALLOC_RANGES'} = {};
    $self->{'NEWLIST'} = [];
    
    bless($self, $class);
    return $self;
}

# Internal Accessors
sub _getbuddy($)   { return $_[0]->{'BUDDY'}; }
sub _gettype($)    { return $_[0]->{'TYPE'}; }
sub _allranges($)  { return $_[0]->{'ALLOC_RANGES'}; }
sub _allnew($)     { return $_[0]->{'NEWLIST'}; }
sub _getrange($$)  { return $_[0]->_allranges()->{$_[1]}; }
sub _putrange($$$) { $_[0]->_allranges()->{$_[1]} = $_[2]; }
sub _newrange($$$) { $_[0]->_putrange($_[1],$_[2]); 
		     push @{$_[0]->_allnew()}, $_[2]; }

#
# XXX: implement
#
sub lock($) {
    my $self = shift;
    return 1;
}

#
# XXX: implement
#
sub unlock($) {
    my $self = shift;
    return 1;
}

#
# Load ranges into this object from the Emulab database.  Also, optionally
# add the subnets for a specified experiment to the set of reservations.
#
# $self   - Reference to class instance.
# $vexperiment - (optional) VirtExperiment object reference.  virtlans
#                that are a member of this experiment will be added to the
#                set of reserved address ranges.
#
sub loadReservedRanges($;$) {
    my ($self, $virtexperiment) = @_;

    my $bud      = $self->_getbuddy();
    my $ranges   = $self->_getranges();
    my $addrtype = $self->_gettype();

    my $qres =
	DBQueryWarn("select * from reserved_addresses where type='$addrtype'");
    return -1
	if (!$qres);

    # Go through each row in the reserved addresses table for the type
    # specified, and add the ranges to the internal buddy allocator.
    # Create and stash an object for other bookkeeping.
    while (my ($ridx, $pid, $eid, $exptidx, $rtime, 
	       $baseaddr, $prefix, $type, $role) = $qres->fetchrow()) 
    {
	my $rval = eval { $bud->embedAddressRange("$baseaddr/$prefix") };
	if ($@) {
	    tberror("Error while embedding reserved address range: $@\n");
	    return -1
	}
	$self->_putrange("$baseaddr/$prefix",
			 IPBuddyWrapper::Allocation->new($exptidx, 
							 "$baseaddr/$prefix"));
    }

    # Add an experiment's virtlans if that parameter was passed in.
    if (defined($virtexperiment)) {
	if (ref($virtexperiment) ne "HASH" ||
	    !$virtexperiment->isa(VirtExperiment)) {
	    tberror("Argument was not a VirtExperiment object!\n");
	    return -1;
	}
	my $exptidx    = $virtexperiment->exptidx();
	my $virtlans   = $virtexperiment->Table("virt_lans");
	foreach my $virtlan (values %{$virtlans}) {
	    my $ip     = inet_aton($virtlan->ip());
	    my $mask   = inet_aton($virtlan->mask());
	    my $prefix = unpack('%32b*', $mask);
	    my $base   = inet_ntoa($ip & $mask);
	    next if !$self->_getrange("$base/$prefix");
	    my $rval   = eval { $bud->embedAddressRange("$base/$prefix") };
	    if ($@) {
		tberror("Error while embedding experiment lan range: $@\n");
		return -1;
	    }
	    $self->_putrange("$base/$prefix",
			     IPBuddyWrapper::Allocation->new($exptidx,
							     "$base/$prefix"));
	}
    }

    return 0;
}

#
# Request an address range from the buddy IP address pool given the
# input (dotted quad) mask and a virt experiment to stash away for
# later when the code needs to push the reservations into the
# database.
#
sub requestAddressRange($$$) {
    my ($self, $virtexperiment, $mask) = @_;

    return undef unless 
	ref($virtexperiment) == "HASH" &&
	defined($mask);

    my $prefix;
    if ($mask =~ /^\d+\.\d+\.\d+\.\d+$/) {
	$prefix = unpack('%32b*', inet_aton($mask));
    } elsif ($prefix =~ /^\d+$/) {
	$prefix = $mask;
    } else {
	tberror("Invalid mask/prefix: $mask\n");
	return undef;
    }

    my $exptidx = $virtexperiment->exptidx();
    my $bud     = $self->_getbuddy();

    my $range = eval { $bud->requestAddressRange($prefix) };
    if ($@) {
	tberror("Error while requesting address range: $@");
	return undef;
    }
    if (!defined($range)) {
	tberror("Could not get a free address range!\n");
	return undef;
    }
    $self->_newrange($range, IPBuddyWrapper::Allocation->new($exptidx,
							     $range));

    return $range;
}

#
# Request the next address from the input range.  It should have been
# previously allocated with requestAddressRange()
#
sub getNextAddress($$) {
    my ($self, $range) = @_;

    return undef
	unless defined($range);

    my $robj = $self->_getrange($range);
    return undef
	unless defined($robj);
    return $robj->getNextAddress();
}

sub DESTROY($) {
    my $self = shift;

    $self->{'BUDDY'} = undef;
    $self->{'ALLOC_RANGES'} = undef;
    $self->{'NEWLIST'} = undef;
}

#
# XXX: implement
#
sub commitReservations($) {
    my ($self) = @_;

    return 0;
}

##############################################################################
#
# Internal module to keep track of address range allocations.
#
package IPBuddyWrapper::Allocation;
use strict;
use English;
use Net::IP;
use libtblog_simple;

sub new($$$) {
    my ($class, $exptidx, $range) = @_;
    my $self = {};

    return undef unless 
	defined($exptidx) && 
	defined($range);

    my $ipobj = Net::IP->new($range);
    if (!defined($ipobj)) {
	tberror(Net::IP::Error() . "\n");
	return undef;
    }
    
    $self->{'EXPTIDX'} = $exptidx;
    $self->{'RANGE'} = $range;
    $self->{'IPOBJ'} = $ipobj;
    
    return $self;
}

# accessors
sub _getobj($) { return $_[0]->{'IPOBJ'}; }
sub _getrange($) { return $_[0]->{'RANGE'}; }

#
# Get next available address in the range. ('+' is overloaded in Net::IP).
#
sub getNextAddress($) {
    my ($self) = @_;

    my $curip = $self->_getobj();
    if (++$curip) {
	return $curip->ip();
    }
    
    return undef;
}

#
# Reset back to base address from this object's range.
#
sub resetAddress($) {
    my $self = $shift;

    my $ipobj = Net::IP->new($self->_getrange());
    $self->{'IPOBJ'} = $ipobj;
}


sub DESTROY($) {
    my $self = shift;

    $self->{'EXPTIDX'} = undef;
    $self->{'RANGE'} = undef;
    $self->{'IPOBJ'} = undef;
}

# Required by perl
1;
