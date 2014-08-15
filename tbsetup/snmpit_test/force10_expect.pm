#!/usr/bin/perl -w

#
# Copyright (c) 2013,2014 University of Utah and the Flux Group.
# Copyright (c) 2006-2014 Universiteit Gent/iMinds, Belgium.
# Copyright (c) 2004-2006 Regents, University of California.
# 
# {{{EMULAB-LGPL
# 
# This file is part of the Emulab network testbed software.
# 
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
# 
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
# 
# }}}
#

#
# Expect module for Force10 switch cli interaction.  A thousand curses to
# Force10 Networks that this module had to be written at all...
#

package force10_expect;
use strict;
use Data::Dumper;

$| = 1; # Turn off line buffering on output

use English;
use Expect;

# Constants
$CONN_TIMEOUT = 60;
$CLI_TIMEOUT  = 15;

sub new($$$$) {

    # The next two lines are some voodoo taken from perltoot(1)
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $name = shift;
    my $debugLevel = shift;
    my $password = shift;  # the password for ssh

    #
    # Create the actual object
    #
    my $self = {};

    #
    # Set the defaults for this object
    # 
    if (defined($debugLevel)) {
        $self->{DEBUG} = $debugLevel;
    } else {
        $self->{DEBUG} = 0;
    }

    $self->{NAME} = $name;
    $self->{PASSWORD} = $password;

    if ($self->{DEBUG}) {
        print "force10_expect initializing for $self->{NAME}, " .
            "debug level $self->{DEBUG}\n" ;
    }

    $self->{CLI_PROMPT} = "$self->{NAME}#";

    # Make it a class object
    bless($self, $class);

    #
    # Lazy initialization of the Expect object is adopted, so
    # we set the session object to be undef.
    #
    $self->{SESS} = undef;

    return $self;
}

#
# Create an Expect object that spawns the ssh process 
# to switch.
#
sub createExpectObject($)
{
    my $self = shift;
    my $id = "$self->{NAME}::createExpectObject()";
    
    my $spawn_cmd = "ssh -l admin $self->{NAME}";
    # Create Expect object and initialize it:
    my $exp = new Expect();
    if (!$exp) {
        # upper layer will check this
        return undef;
    }
    $exp->raw_pty(0);
    $exp->log_stdout(0);
    if (!$exp->spawn($spawn_cmd)) {
	warn "$id: Cannot spawn $spawn_cmd: $!\n";
	return undef;
    }
    $exp->expect($CONN_TIMEOUT,
         ["admin\@$self->{NAME}'s password:" => sub { my $e = shift;
                               $e->send($self->{PASSWORD}."\n");
                               exp_continue;}],
         ["Permission denied" => sub { $error = "Password incorrect!";} ],
         [ timeout => sub { $error = "Timeout connecting to switch!";} ],
         $self->{CLI_PROMPT} );

    if (!$error && $exp->error()) {
	$error = $exp->error();
    }

    if ($error) {
	warn "$id: Could not connect to switch: $error\n";
	return undef;
    }

    return $exp;
}

#
# Utility function - return the configuration prompt string for a given
# interface name.
#
sub conf_iface_prompt($) {
    my $iface = shift;
    my $suffix = "";
    IFNAME: for ($iface) {
	/vlan(\d+)/i && do {$suffix = "vl-$1"; last IFNAME;};
	/(te|fo)(\d+\/\d+)/i && do {$suffix = "$1-$2"; last IFNAME;};
	/po(\d+)/i && do {$suffix = "po-$1"; last IFNAME;};
	return undef; # default case: invalid/unhandled iface name
    }
    return $self->{NAME} . '(conf-if-' . $suffix . ')#';
}

#
# Run a CLI command (or config command), checking for errors.
#
# Parameters:
# $cmd - The CLI command to run in the given context.
# $confmode - Is this a configuration command? 1 for yes, 0 for no
# $iface - Name of interface to exec config command against.
#
sub doCLICmd($$;$$)
{
    my ($self, $cmd, $confmode, $iface) = @_;
    $confmode ||= 0;
    $iface    ||= "";

    my $output = "";
    my $error = "";
    my @active_sets;

    my $exp = $self->{SESS};

    if (!$exp) {
	#
	# Create the Expect object, lazy initialization.
	#
	# We'd better set a long timeout on Apcon switch
	# to keep the connection alive.
	$self->{SESS} = $self->createExpectObject();
	if (!$self->{SESS}) {
	    warn "WARNING: Unable to connect to $self->{NAME}\n";
	    return (1, "Unable to connect to switch $self->{NAME}.");
	}
	$exp = $self->{SESS};
    }

    # Config prompt match strings.
    my $conf_prompt_str = $self->{NAME} . '(conf)#';
    my $conf_any_prompt_re = quotemeta($self->{NAME}) . '\(conf.*\)#';

    # Common patterns
    my $catch_error_pat  = [qr/\% Error: (.+?)\n/,
			    sub {my $e = shift; $error = ($e->matchlist)[0]}];
    my $timeout_pat      = [timeout => sub { $error = "timed out.";}];
    my $enter_config_pat = [$self->{CLI_PROMPT},
			    sub {my $e = shift; $e->send("conf t\n")}];
    my $end_config_pat   = [qr/$conf_any_prompt_re/,
			    sub {my $e = shift; $e->send("end\n")}];

    # Common pattern sets
    my $enter_config_set = [$enter_config_pat];
    my $end_config_set   = [$end_config_pat];

    #
    # Sets of pattern sets for execution follow.
    #

    # Just pop off one command without going into config mode.
    my @single_command_sets = ();
    push (@single_command_sets,
	  [
	     [$self->{CLI_PROMPT}, sub {my $e = shift; $e->send("$cmd\n")}]
	  ],
	  [
	     [$self->{CLI_PROMPT}, sub {my $e = shift; 
					$output = $e->before();}]
	  ]
	);

    # Perform a single config operation (go into config mode).
    my @single_config_sets = ();
    push (@single_config_sets,
	  $enter_config_set,
	  [
	     [$conf_prompt_str, sub {my $e = shift; $e->send("$cmd\n");}]
	  ],
	  [
	     [$conf_prompt_str, sub {my $e = shift; $output = $e->before();}]
	  ],
	  $end_config_set
	);

    # Do an interface config operation (go into iface-specific config mode).
    my @iface_config_sets = ();
    push (@iface_config_sets,
	  $enter_config_set,
	  [
	     [$conf_prompt_str, sub {my $e = shift; 
				     $e->send("interface $iface\n");}]
	  ],
	  [
	     [conf_iface_prompt($iface), sub {my $e = shift; 
					      $e->send("$cmd\n");}]
	  ],
	  [
	     [conf_iface_prompt($iface), sub {my $e = shift; 
					      $output = $e->before();}]
	  ],
	  $end_config_set
	);

    # Pick "set of sets" to use with Expect based on how this method
    # was called.
    if ($confmode) {
	if ($iface) {
	    @active_sets = @iface_config_sets;
	} else {
	    @active_sets = @single_config_sets;
	}
    } else {
	@active_sets = @single_command_sets;
    }

    $exp->send("\cC"); # Send Ctrl-C to bail out of anything on the cmd line.
    $exp->send("end\n"); # Attempt to exit config mode as a precaution.
    $exp->clear_accum(); # Clean any accumulated output.
    $exp->send("\cC"); # Get a command prompt into the Expect accumulator.
    # Match across the selected set of patterns.
    foreach my $patset (@active_sets) {
	$exp->expect($CLI_TIMEOUT,
		     $catch_error_pat,
		     @$patset,
		     $timeout_pat);
    }

    if (!$error && $exp->error()) {
	$error = $exp->error();
    }

    if ($error) {
	$self->debug("force10_expect: Error in doCLICmd: $error\n");
        return (1, $error);
    } else {
        return (0, $output);
    }
}
