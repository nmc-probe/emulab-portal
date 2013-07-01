#!/usr/bin/perl -w

#
# Copyright (c) 2013 University of Utah and the Flux Group.
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


# Mellanox XML-Gateway handler class.  Hides all of the connection
# management, method invocation, and response parsing goo from the caller.

package MLNX_XMLGateway;

use URI;
use LWP::UserAgent;
use LWP::ConnCache;
use XML::LibXML;

use strict;

$| = 1; # Turn off line buffering on output

my $MLNX_GATEWAY_PATH = "/xtree";
my $MLNX_AUTH_PATH  = '/admin/launch?script=rh&template=login&action=login';
my %MLNX_ACTIONS = ("action"     => 1, 
		    "get"        => 1, 
		    "set-create" => 1, 
		    "set-modify" => 1, 
		    "set-delete" => 1);

#
# Create a new Mellanox XML-Gateway object.  $authority is an authority
# component for an HTTP URI.  e.g., 'user:pass@hostname[:port]'
#
# user, password, and hostname components are required.  Port is optional.
#
sub new($$) {
    my ($class,$authority) = @_;
    my $self = {};
    my ($user,$pass);

    # User needs to pass in the authority string.
    defined($authority) or die "Must supply an authority string.";

    # Construct URI from input argument, and extract username/password.
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->authority($authority);
    my $uinfo = $uri->userinfo();
    if (defined($uinfo) && $uinfo =~ /^(.+):(.+)$/) {
	$user = $1;
	$pass = $2;
    } else {
	die "Username and password must be present in URI authority string.";
    }
    $uri->userinfo(''); # clear user/pass from the URI now that we have it.
    $uri->path($MLNX_GATEWAY_PATH); # Tack on the API entry point path.

    $self->{'AUTHORITY'} = $authority;
    $self->{'URI'} = $uri;
    $self->{'USER'} = $user;
    $self->{'PASS'} = $pass;
    $self->{'CONN'} = undef;

    bless($self, $class);
    return $self;
}

# Ensure all of the objects we are storing get de-allocated when an instance
# of this class goes away.
sub DESTROY($) {
    my ($self,) = @_;

    $self->{'AUTHORITY'} = undef;
    $self->{'URI'} = undef;
    $self->{'USER'} = undef;
    $self->{'PASS'} = undef;
    $self->{'CONN'} = undef;
}

#
# Establish an authenticated session with the XML gateway on the switch.
# Users of this module should not call this method directly.
#
sub connect($) {
    my ($self,) = @_;

    # Set when this object was created.
    my $user = $self->{'USER'};
    my $pass = $self->{'PASS'};

    # See if we have a connection, and if it is still valid/active.
    if (defined($self->{'CONN'})) {
	my $ccache = $self->{'CONN'}->conn_cache();
	$ccache->prune();  # test the connection, and remove if closed.
	if (scalar($ccache->get_connections()) == 1) {
	    # Existing connection is valid - pass it back to the caller.
	    return $self->{'CONN'};
	} else {
	    # De-alloc the connection object.  We will try to reconnect
	    # and authenticate again below.
	    $ccache = undef;
	    $self->{'CONN'} = undef;
	}
    }

    my $ua = LWP::UserAgent->new();
    $ua->conn_cache(LWP::ConnCache->new()); # need an http 1.1 session.
    $ua->cookie_jar({});

    # Create a new URI with the host defined in the URI created via
    # the constructor.
    my $authuri = URI->new();
    $authuri->scheme('http');
    $authuri->host($self->{'URI'}->host());
    # Tack on the goofy query path to the URI, where we will post the
    # authentication form.  See the MLNX-OS REST API docs.
    $authuri->path_query($MLNX_AUTH_PATH);
    # The user/password fields we need to supply in the form to be posted.
    my %form = (
	'f_user_id'  => $user,
	'f_password' => $pass
    );
    # Make the call and check that it went through OK.  Die if not.
    # XXX: may want to put in some retry logic, and/or check for timeout.
    my $authres = $ua->post($authuri, \%form);
    if ($authres->code != 302) {
	die "Failed to authenticate to ". $authuri->host() .": ".
	    $authres->dump();
    }

    # Connected.  Stash the LWP::UserAgent object and pass it back to caller.
    $self->{'CONN'} = $ua;
    return $ua;
}


#
# Invoke a list of calls (all sent simultaneously to the switch).  This is
# the primary interface for users of this module.
#
sub call($$) {
    my ($self, $calls) = @_;

    my @callstack = ();

    defined($calls) && ref($calls) eq "ARRAY"
	or die "Expected an array reference containing calls to invoke.";

    # If there is more than one call (array of array refs), encode them
    # all and put them on the stack.  Otherwise just encode the one
    # call.
    if (ref($calls->[0]) eq "ARRAY") {
	foreach my $call (@{$calls}) {
	    # will die() if it encounters a problem, which we let flow through.
	    push @callstack, XMLEncodeCall(@{$call});
	}
    } else {
	push @callstack, XMLEncodeCall(@{$calls});
    }

    # will die() if it encounters a problem, which we let flow through.
    return $self->DispatchCallStack(XMLEncodeCallStack(@callstack));
}

#
# Encode an XML-gateway RPC into an XML document fragment.  Meant
# for internal use by this module.
#
sub XMLEncodeCall($$;$) {
    my ($action, $restpath, $arguments) = @_;

    # Sanity checks for input arguments.
    defined($action) && defined($restpath)
	or die "Must supply 'action' and 'REST-path' parameters.";

    exists($MLNX_ACTIONS{$action})
	or die "Unknown call type: $action";

    $restpath =~ qr|^(/[\w\*]+){1,}/?$|
	or die "REST-path does not look valid: $restpath";

    if (defined($arguments) && ref($arguments) eq "HASH") {
	$action ne "action" && $action ne "set-modify"
	    and die "Must NOT supply arguments hash with 'set-create', 'set-delete' or 'get' calls.";
	# Append arguments on to the REST-path.
	while (my ($arg_name,$arg_val) = each %{$arguments}) {
	    $restpath .= "|${arg_name}=${arg_val}";
	}
    } else {
	$action eq "action" || $action eq "set-modify"
	    and die "Must supply an arguments hash with 'action' or 'set-modify' calls.";
    }

    # Conjure a partial XML tree for this call.
    my $node = XML::LibXML::Element->new("node");
    $node->appendTextChild("name", $action);
    $node->appendTextChild("type", "string");
    $node->appendTextChild("value", $restpath);

    return $node;
}


#
# Create the full XML-gateway RPC request, adding the set of
# individual calls passed in (preserving their order).  Meant for
# internal use by this module.
#
sub XMLEncodeCallStack(@) {
    my @callstack = @_;

    scalar(@callstack) > 0
	or die "Must pass in at least one call to add";

    # Create the boilerplate that wraps the RPCs to send.
    my $dom = XML::LibXML->createDocument("1.0", "UTF-8");
    $dom->setStandalone(0);

    my $root  = $dom->createElement("xg-request");
    my $areq  = $dom->createElement("action-request");
    my $aname = $dom->createElement("action-name");
    my $anval = $dom->createTextNode("/do_rest");
    my $nodes = $dom->createElement("nodes");

    $dom->setDocumentElement($root);
    $root->appendChild($areq);
    $areq->appendChild($aname);
    $aname->appendChild($anval);
    $areq->appendChild($nodes);

    # drop in each of the call nodes (created by XMLEncodeCall()).
    foreach my $call (@callstack) {
	$nodes->appendChild($call);
    }

    return $dom;
}

#
# Kick the XML encoded RPC structure over to the switch for processing.
# Handle any errors that might be transient (retry).  For internal module
# use only.
#
sub DispatchCallStack($$) {
    my ($self, $dom) = @_;

    # Grab the LWP::UserAgent object for this switch.
    my $ua = $self->connect();
    defined($ua) or die "Could not get connection object.";
    
    my $resp = $ua->post($self->{'URI'},
			 Content => $dom->serialize());

    if ($resp->is_error()) {
	print "Error while calling XML-gateway. XML callstack:\n".
	    $dom->serialize() ."\n\n".
	    "Server output: ". $resp->dump() ."\n";
	die "Error dispatching call stack.";
    }

    # Parse the XML encoded response from the gateway into a DOM object.
    # Note: will harf up a die() exception if the result isn't valid XML.
    my $respdom = eval { XML::LibXML->load_xml(string => 
					       $resp->decoded_content()) };
    if ($@) {
	print "Invalid gateway response (not XML?).  Full HTTP contents:\n".
	      $resp->dump() ."\n";
	die "Invalid gateway response (not XML?).";
    }

    # Allow any die() exceptions to just flow on through.
    return XMLDecodeResponse($respdom);
}


#
# Extract the salient bits from the returned XML, and return these to caller.
# Also look for errors codes/messages and throw them if found.
#
sub XMLDecodeResponse($) {
    my ($respdom,) = @_;

    # Check the return code for errors.
    my $rcode_xlist = $respdom->findnodes("//return-code");
    my $rmsg_xlist  = $respdom->findnodes("//return-msg");
    $rcode_xlist->size() && $rmsg_xlist->size()
	or die "Return code and/or message missing from XML-gateway response.";
    my $code = $rcode_xlist->string_value();
    $code == 0 or die ("XML-gateway error: $code ".
		       "Message: ". $rmsg_xlist->string_value());

    # Grab all of the elements matching "node" that are subnodes of
    # the "nodes" element.  XPath rocks!
    my $nodes_xlist = $respdom->findnodes("//nodes/node");

    # Return an empty list of there aren't any data nodes in the response.
    return () if !defined($nodes_xlist);

    # Process the list of data nodes.  Extract the path,type,value
    # tuples from the XML and return these as a list of anonymous arrays.
    my @nodelist = $nodes_xlist->map(
	sub {
	    my ($el) = @_;
	    my $restpath = $el->findnodes("name");
	    my $type     = $el->findnodes("type");
	    my $value    = $el->findnodes("value");
	    $restpath->size() && $type->size() && $value->size()
		or die "Expected parameter(s) missing from XML-gateway ".
		"response node.";
	    return [$restpath->string_value(),
		    $type->string_value(),
		    $value->string_value()];
	});

    return @nodelist;
}
