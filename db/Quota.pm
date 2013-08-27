#!/usr/bin/perl -wT
#
# Copyright (c) 2012,2013 University of Utah and the Flux Group.
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
package Quota;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA    = "Exporter";
@EXPORT = qw ( );

use libdb;
use libtestbed;
use EmulabConstants;
use User;
use Group;
use Project;
use English;
use Date::Parse;
use Data::Dumper;
use overload ('""' => 'Stringify');

my @QUOTA_TYPES  = ("ltdataset",);
my $MINQUOTASIZE = 1 # 1 mebibyte
my $MAXQUOTASIZE = 1024 * 1024 * 1024 # 1 pebibyte

# Cache of instances to avoid regenerating them.
my %quotas	= ();
my $debug	= 0;

# Little helper and debug function.
sub mysystem($)
{
    my ($command) = @_;

    print STDERR "Running '$command'\n"
	if ($debug);
    return system($command);
}

#
# Accessors
#
sub idx($)             {return $_[0]->{'DBROW'}->{'quota_idx'}; }
sub quota_idx($)       {return $_[0]->idx(); }
sub quota_id($)        {return $_[0]->{'DBROW'}->{'quota_id'}; }
sub pid($)             {return $_[0]->{'DBROW'}->{'pid'}; }
sub type($)            {return $_[0]->{'DBROW'}->{'type'}; }
sub size($)            {return $_[0]->{'DBROW'}->{'size'}; }
sub notes($)           {return $_[0]->{'DBROW'}->{'notes'}; }
sub last_update($)     {return str2time($_[0]->{'DBROW'}->{'last_update'}); }

#
# Lookup a quota in the DB and return an object representing it.
#
sub Lookup($$;$)
{
    my ($class, $pid, $quota_id) = @_;
    my ($wclause);

    # Determine how we were called.  If only a single parameter was passed
    # to the method, then it should be a quota index.  If both are passed in,
    # then they are what their variable names imply.
    if (!defined($quota_id)) {
	my $idx = $pid;
	if ($idx !~ /^\d+$/) {
	    print STDERR "Quota->Lookup: single parameter to call must be a numeric index.\n";
	    return undef;
	}
	# Look in cache first
	return $quotas{$idx}
	    if (exists($quotas{$idx}));

	$wclause = "quota_idx=$idx";
    } else {
	# Look in cache first
	return $quotas{"$pid:$quota_id"}
	    if (exists($quotas{"$pid:$quota_id"}));

	$wclause = "pid='$pid' and quota_id='$quota_id'";
    }

    my $self              = {};

    # Load quota from DB, if it exists. Otherwise, return undef.
    my $query_result =
	DBQueryWarn("select * from project_quotas where $wclause");

    return undef
	if (!$query_result || !$query_result->numrows);

    $self->{'DBROW'} = $query_result->fetchrow_hashref();;
    bless($self, $class);

    # Add to cache (dual lookup).
    $quotas{$self->pid() + ":" + $self->quota_id()} = $self;
    $quotas{$self->idx()} = $self;
    return $self;
}

#
# Force a reload of the data.
#
sub LookupSync($$;$) {
    my ($class, $pid, $quota_id) = @_;
    my ($quota_idx, $plid);

    if (!defined($quota_id)) {
	$quota_idx = $pid;
	if (exists($quotas{$quota_idx})) {
	    $plid = 
		$quotas{$quota_idx}->pid() + ":" + 
		$quotas{$quota_idx}->quota_id();
	}
    } else {
	$plid = "$pid:$quota_id";
	if (exists($quotas{$plid})) {
	    $quota_idx = $quotas{$plid}->idx();
	}
    }

    # delete from cache
    delete($quotas{$quota_idx})
        if (defined($quota_idx) && exists($quotas{$quota_idx}));
    delete($quotas{$plid})
        if (defined($plid) && exists($quotas{$plid}));

    return Lookup($class, $quota_idx);
}

#
# explicit object destructor to ensure we get rid of circular refs.
#
sub DESTROY($) {
    my ($self) = @_;

    $self->{'DBROW'} = undef;
}

#
# Create a new quota.
#
sub Create($$;$) {
    my ($class, $argref, $attrs) = @_;

    my ($quota_id, $pid, $type, $size, $notes);

    return undef
	if (!ref($argref));

    $quota_id  = $argref->{'quota_id'};
    $pid       = $argref->{'pid'};
    $type      = $argref->{'type'};
    $size      = $argref->{'size'};
    $notes     = $argref->{'notes'} || "";
    
    if (!($quota_id && $pid && $type && $size)) {
	print STDERR "Quota->Create: Missing required parameters in argref\n";
	return undef;
    }

    # Sanity checks for incoming arguments
    if (!TBcheck_dbslot($quota_id, "project_quotas", "quota_id")) {
	print STDERR "Quota->Create: Bad data for quota id: ". 
	    $DBFieldErrstr ."\n";
	return undef;
    }

    if (ref($pid) ne "Project") {
	my $npid = Project->Lookup($pid);
	if (!defined($npid)) {
	    print STDERR "Quota->Create: Bad/Unknown project: $pid\n";
	    return undef;
	}
	$pid = $npid;
    }

    # User must belong to incoming project.  The code calling into Create()
    # should have already checked to be sure that the caller has permission
    # to create the quota in the first place.
    if (!$pid->LookupUser($uid)) {
	print STDERR "Quota->Create: User $uid is not a member of project $pid\n";
	return undef;
    }
    
    # If quota types ever grow to be many and complex, then this info will
    # have to come from a DB table instead of a static list in this module.
    if (!grep {/^$type$/} @QUOTA_TYPES) {
	print STDERR "Quota->Create: Unknown quota type: $type\n";
	return undef;
    }

    # XXX: quota size limits should be changeable via sitevar.
    if ($size !~ /^\d+$/) {
	print "Quota->Create: Invalid quota size: $size\n";
	return undef;
    }
    if ($size < $MINQUOTASIZE || $size > $MAXQUOTASIZE) {
	print STDERR "Quota->Create: Quota is either too small or too big ($MINQUOTASIZE/$MAXQUOTASIZE).\n";
	return undef;
    }

    # If present, make sure the note is not too outrageously long.
    my $safe_notes;
    if (defined($notes) && $notes) {
	if (!TBcheck_dbslot($notes, "project_quotas", "notes")) {
	    print STDERR "Quota->Create: Bad data in notes: ".
		$DBFieldErrstr ."\n";
	    return undef;
	}
	$safe_notes = DBQuoteSpecial($notes);	
    } else {
	$safe_notes = "";
    }

    # Get a unique quota index and slam this stuff into the DB.
    my $quota_idx = TBGetUniqueIndex('next_quotaidx');

    DBQueryWarn("insert into project_quotas set ".
		"quota_idx=$quota_idx,".
		"quota_id='$quota_id',".
		"pid='". $pid->pid() ."',".
		"type='$type',".
		"size=$size,".
		"notes='$safe_notes'")
	or return undef;

    return Lookup($class, $pid->pid(), $quota_id);
}

#
# Delete an existing quota.
#
sub Delete($) {
    my ($self) = @_;

    return -1
	if (!ref($self));

    my $idx  = $self->idx();
    my $qpid = $self->pid() + ":" + $self->quota_id();

    DBQueryWarn("delete from project_quotas where quota_idx=$idx")
	or return -1;
    
    delete($quotas{$idx})
	if (exists($quotas{$idx}));
    delete($quotas{$qpid})
	if (exists($quotas{$qpid}));

    return 0
}

#
# Return a list of all quotas belonging to a particular project.
#
sub AllProjectQuotas($$)
{
    my ($class, $pid)  = @_;
    my @pquotas = ();
    
    return undef
	if !defined($pid);

    if (ref($pid) eq "Project") {
	$pid = $pid->pid();
    }
    
    my $query_result =
	DBQueryWarn("select quota_id from project_quotas where pid='$pid'");
    
    return ()
	if (!$query_result || !$query_result->numrows);

    while (my ($quota_id) = $query_result->fetchrow_array()) {
	my $quota = Lookup($class, $pid, $quota_id);

	# Something went wrong?
	return ()
	    if (!defined($quota));
	
	push(@pquotas, $quota);
    }
    return @pquotas;
}

#
# Update fields in the project_quotas table, as requested.
#
sub Update($$)
{
    my ($self, $argref) = @_;

    # Must be a real reference. 
    return -1
	if (! ref($self));

    my $idx = $self->idx();
    my @sets   = ();

    foreach my $key (keys(%{$argref})) {
	my $val = $argref->{$key};

	# Don't let caller update the quota's index - that would be bad.
	return -1
	    if ($key eq "quota_idx");

	# Treat NULL special.
	push (@sets, "${key}=" . ($val eq "NULL" ?
				  "NULL" : DBQuoteSpecial($val)));
    }

    my $query = "update project_quotas set " . join(",", @sets) .
	" where quota_idx='$idx'";

    return -1
	if (! DBQueryWarn($query));

    return Refresh($self);
}

#
# Refresh a class instance by reloading from the DB.
#
sub Refresh($)
{
    my ($self) = @_;

    return -1
	if (! ref($self));

    my $idx = $self->idx();

    my $query_result =
	DBQueryWarn("select * from project_quotas ".
		    " where quota_idx='$idx'");

    return -1
	if (!$query_result || !$query_result->numrows);

    $self->{"DBROW"}    = $query_result->fetchrow_hashref();

    return 0;
}

#
# Update the notes for a quota entry.
#
sub UpdateNotes($$) {
    my ($self, $notes) = @_;

    return -1
	if (!ref($self));

    return -1
	if (!defined($notes));

    if (!TBcheck_dbslot($notes, "project_quotas", "notes")) {
	print STDERR "Quota->UpdateNotes: Bad data in notes: ".
	    $DBFieldErrstr ."\n";
	return -1;
    }
    my $safe_notes = DBQuoteSpecial($notes);	

    my $idx = $self->idx();
    DBQueryWarn("update project_quotas set notes='$safe_notes' ".
		"where quota_idx=$idx")
	or return -1;

    return 0;
}

#
# Add space to an existing quota
#
sub IncreaseSize($$) {
    my ($self, $incr) = @_;

    return -1
	if (!ref($self));

    if ($incr < $MINQUOTASIZE || $self->size() + $incr > $MAXQUOTASIZE) {
	print STDERR "Quota->IncreaseSize: Size increment is either too small or the new total is too big ($MINQUOTASIZE/$MAXQUOTASIZE).\n";
	return -1
    }

    my $idx = $self->idx();
    my $newsize = $self->size() + $incr;
    DBQueryWarn("update project_quotas set size=$newsize where quota_idx=$idx")
	or return -1;

    return 0;
}

#
# Set a specific quota size.
#
sub SetSize($$) {
    my ($self, $size) = @_;

    return -1
	if (!ref($self));

    if ($size < $MINQUOTASIZE || $size > $MAXQUOTASIZE) {
	print STDERR "Quota->SetSize: New quota size is either too small or too big ($MINQUOTASIZE/$MAXQUOTASIZE).\n";
	return -1
    }

    my $idx = $self->idx();
    DBQueryWarn("update project_quotas set size=$size where quota_idx=$idx")
	or return -1;

    return 0;
}

#
# Stringify for output.
#
sub Stringify($)
{
    my ($self) = @_;
    
    my $quota_id  = $self->quota_id();
    my $pid  = $self->pid();
    my $size = $self->size();

    return "[Quota: $pid/$quota_id/${size}MiB]";
}

# _Always_ make sure that this 1 is at the end of the file...

1;
