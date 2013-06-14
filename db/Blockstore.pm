#!/usr/bin/perl -wT
#
# Copyright (c) 2012-2013 University of Utah and the Flux Group.
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
package Blockstore;

use strict;
use Carp;
use Exporter;
use vars qw(@ISA @EXPORT $AUTOLOAD);

@ISA = qw(Exporter);
@EXPORT = qw ( );

use libdb;
use libtestbed;
use English;
use Data::Dumper;
use overload ('""' => 'Stringify');

my $debug	= 0;

#
# Lookup a (physical) storage object type and create a class instance to 
# return.
#
sub Lookup($$$)
{
    my ($class, $nodeid, $bsid) = @_;

    return undef
	if (! ($nodeid =~ /^[-\w]+$/ && $bsid =~ /^[-\w]+$/));

    my $query_result =
	DBQueryWarn("select * from blockstores ".
		    "where node_id='$nodeid' and bs_id='$bsid'");

    return undef
	if (!$query_result || !$query_result->numrows);

    my $self         = {};
    $self->{"HASH"}  = {};
    $self->{"DBROW"} = $query_result->fetchrow_hashref();

    bless($self, $class);
    return $self;
}

# To avoid writing out all the methods.
AUTOLOAD {
    my $self  = $_[0];
    my $name  = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    # A DB row proxy method call.
    if (exists($self->{'DBROW'}->{$name})) {
	return $self->{'DBROW'}->{$name};
    }

    # Local storage slot.
    if ($name =~ /^_.*$/) {
	if (scalar(@_) == 2) {
	    return $self->{'HASH'}->{$name} = $_[1];
	}
	elsif (exists($self->{'HASH'}->{$name})) {
	    return $self->{'HASH'}->{$name};
	}
    }
    carp("No such slot '$name' field in $self");
    return undef;
}

# Break circular reference someplace to avoid exit errors.
sub DESTROY {
    my $self = shift;

    $self->{"DBROW"}    = undef;
    $self->{"HASH"}     = undef;
}

#
# Stringify for output.
#
sub Stringify($)
{
    my ($self) = @_;
    
    my $bsidx   = $self->bsidx();
    my $bs_id   = $self->bs_id();
    my $node_id = $self->node_id();

    return "[BlockStore:$bsidx, $bs_id, $node_id]";
}

#
# Blockstores are reserved to a pcvm; that is how we do the
# bookkeeping. When a node is released (nfree), we can find
# the reserved blockstores for that node, reset the capacity
# in the blockstore_state table, and delete the row(s).
#
sub Reserve($$$$$)
{
    my ($self, $experiment, $vnode_id, $bs_name, $bs_size) = @_;
    my $exptidx    = $experiment->idx();
    my $pid        = $experiment->pid();
    my $eid        = $experiment->eid();
    my $bsidx      = $self->bsidx();
    my $bs_id      = $self->bs_id();
    my $bs_node_id = $self->node_id();
    my $remaining_capacity;

    DBQueryWarn("lock tables blockstores read, ".
		"            reserved_blockstores write, ".
		"            blockstore_state write")
	or return -1;

    #
    # Need the remaining size to make sure we can allocate it.
    #
    my $query_result =
	DBQueryWarn("select remaining_capacity from blockstore_state ".
		    "where bsidx='$bsidx'");
    goto bad
	if (!$query_result);

    #
    # Just in case the state row is missing, okay to create it.
    #
    if (!$query_result->numrows) {
	$remaining_capacity = $self->total_size();

	DBQueryWarn("insert into blockstore_state set ".
		    "  bsidx='$bsidx', node_id='$bs_node_id', bs_id='$bs_id', ".
		    "  remaining_capacity='$remaining_capacity', 'ready=1'")
	    or goto bad;
    }
    else {
	($remaining_capacity) = $query_result->fetchrow_array();
    }
    if ($bs_size > $remaining_capacity) {
	print STDERR "Not enough remaining capacity on $bsidx\n";
	goto bad;
    }

    #
    # If we do not have a reservation row, create one with a zero
    # size, to indicate nothing has actually been reserved in the
    # blockstore_state table.
    #
    $query_result =
	DBQueryWarn("select size from reserved_blockstores ".
		    "where exptidx='$exptidx' and bsidx='$bsidx' and ".
		    "       vname='$bs_name'");
    goto bad
	if (!$query_result);

    if (! $query_result->numrows) {
	if (! DBQueryWarn("insert into reserved_blockstores set ".
	        "  bsidx='$bsidx', node_id='$bs_node_id', bs_id='$bs_id', ".
	        "  vname='$bs_name', pid='$pid', eid='$eid', ".
		"  size='0', vnode_id='$vnode_id', ".
	        "  exptidx='$exptidx', rsrv_time=now()")) {
	    goto bad;
	}
    }
    else {
	my ($current_size) = $query_result->fetchrow_array();

	#
	# At the moment, I am not going to allow the blockstore
	# to change size. 
	#
	if ($current_size && $current_size != $bs_size) {
	    print STDERR "Not allowed to change size of existing store\n";
	    goto bad;
	}

	#
	# If already have a reservation size, then this is most
	# likely a swapmod, and we can just return without doing
	# anything.
	#
	goto done
	    if ($current_size);
    }

    #
    # Now do an atomic update that changes both tables.
    #
    if (!DBQueryWarn("update blockstore_state,reserved_blockstores set ".
		"     remaining_capacity=remaining_capacity-${bs_size}, ".
		"     size='$bs_size' ".
		"where blockstore_state.bsidx=reserved_blockstores.bsidx and ".
		"      blockstore_state.bs_id=reserved_blockstores.bs_id and ".
		"      reserved_blockstores.bsidx='$bsidx' and ".
		"      reserved_blockstores.exptidx='$exptidx' and ".
		"      reserved_blockstores.vnode_id='$vnode_id'")) {
	goto bad;
    }
done:
    DBQueryWarn("unlock tables");
    return 0;
  bad:
    DBQueryWarn("unlock tables");
    return -1;
}

############################################################################
#
# Package to describe a specific reservation of a blockstore.
#
package Blockstore::Reservation;
use libdb;
use libtestbed;
use English;
use vars qw($AUTOLOAD);
use overload ('""' => 'Stringify');

#
# Lookup a blockstore reservation.
#
sub Lookup($$$$)
{
    my ($class, $blockstore, $experiment, $vname) = @_;

    return undef
	if (! ($vname =~ /^[-\w]+$/ && ref($blockstore) && ref($experiment)));

    my $exptidx = $experiment->idx();
    my $bsidx   = $blockstore->bsidx();

    my $query_result =
	DBQueryWarn("select * from reserved_blockstores ".
		    "where exptidx='$exptidx' and bsidx='$bsidx' and ".
		    "       vname='$vname'");

    return undef
	if (!$query_result || !$query_result->numrows);

    my $self         = {};
    $self->{"HASH"}  = {};
    $self->{"DBROW"} = $query_result->fetchrow_hashref();

    bless($self, $class);
    return $self;
}

#
# Look for the blockstore associated with a pcvm. At the present
# time, one blockstore is mapped to one pcvm. 
#
sub LookupByNodeid($$)
{
    my ($class, $vnode_id) = @_;

    my $query_result =
	DBQueryWarn("select * from reserved_blockstores ".
		    "where vnode_id='$vnode_id'");

    return undef
	if (!$query_result || !$query_result->numrows);

    if ($query_result->numrows != 1) {
	print STDERR "Too many blockstores for $vnode_id!\n";
	return -1;
    }

    my $self         = {};
    $self->{"HASH"}  = {};
    $self->{"DBROW"} = $query_result->fetchrow_hashref();

    bless($self, $class);
    return $self;
}

# To avoid writing out all the methods.
AUTOLOAD {
    my $self  = $_[0];
    my $name  = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    # A DB row proxy method call.
    if (exists($self->{'DBROW'}->{$name})) {
	return $self->{'DBROW'}->{$name};
    }
    carp("No such slot '$name' field in $self");
    return undef;
}

# Break circular reference someplace to avoid exit errors.
sub DESTROY {
    my $self = shift;

    $self->{"DBROW"}    = undef;
    $self->{"HASH"}     = undef;
}

#
# Stringify for output.
#
sub Stringify($)
{
    my ($self) = @_;
    
    my $bsidx   = $self->bsidx();
    my $bs_id   = $self->bs_id();
    my $node_id = $self->node_id();
    my $vname   = $self->vname();

    return "[BlockStore:$bsidx, $bs_id, $node_id ($vname)]";
}

#
# Blockstores are reserved to a pcvm; that is how we do the
# bookkeeping. When a node is released (nfree), we can find
# the reserved blockstore for that node, reset the capacity
# in the blockstore_state table, and delete the row(s).
#
sub Release($)
{
    my ($self)     = @_;
    my $exptidx    = $self->exptidx();
    my $bsidx      = $self->bsidx();
    my $bs_id      = $self->bs_id();
    my $bs_node_id = $self->node_id();
    my $vnode_id   = $self->vnode_id();
    my $size       = $self->size();

    DBQueryWarn("lock tables blockstores read, ".
		"            reserved_blockstores write, ".
		"            blockstore_state write")
	or return -1;

    #
    # Need the remaining size to deallocate.
    #
    my $query_result =
	DBQueryWarn("select remaining_capacity from blockstore_state ".
		    "where bsidx='$bsidx'");
    goto bad
	if (!$query_result);

    if (!$query_result->numrows) {
	print STDERR "No blockstore state for $bsidx\n";
	goto bad;
    }

    #
    # We want to atomically uupdate update remaining_capacity and
    # set the size in the reservation to zero, so that if we fail,
    # nothing has changed.
    #
    if (!DBQueryWarn("update blockstore_state,reserved_blockstores set ".
		"     remaining_capacity=remaining_capacity+size, ".
		"     size=0 ".
		"where blockstore_state.bsidx=reserved_blockstores.bsidx and ".
		"      blockstore_state.bs_id=reserved_blockstores.bs_id and ".
		"      reserved_blockstores.bsidx='$bsidx' and ".
		"      reserved_blockstores.exptidx='$exptidx' and ".
		"      reserved_blockstores.vnode_id='$vnode_id'")) {
	goto bad;
    }
    # That worked, so now we can delete the reservation row.
    DBQueryWarn("delete from reserved_blockstores ".
		"where reserved_blockstores.bsidx='$bsidx' and ".
		"      reserved_blockstores.exptidx='$exptidx' and ".
		"      reserved_blockstores.vnode_id='$vnode_id'")
	or goto bad;

    DBQueryWarn("unlock tables");
    return 0;
  bad:
    DBQueryWarn("unlock tables");
    return -1;
}

# _Always_ make sure that this 1 is at the end of the file...
1;
