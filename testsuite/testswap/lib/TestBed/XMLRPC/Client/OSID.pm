#!/usr/bin/perl
#
# EMULAB-COPYRIGHT
# Copyright (c) 2009 University of Utah and the Flux Group.
# All rights reserved.
#
package TestBed::XMLRPC::Client::OSID;
use SemiModern::Perl;
use Mouse;
use Data::Dumper;

extends 'TestBed::XMLRPC::Client';

#autoloaded/autogenerated/method_missings/etc getlist

=head1 NAME

TestBed::XMLRPC::Client::OSID

=over 4

=item C<getlist>

returns a list of available OS images 

=item C<info($image_name)>

returns the detailed info for image $image_name

=back

=cut

sub info { shift->augment( 'osid' => shift, @_ ); }

1;
