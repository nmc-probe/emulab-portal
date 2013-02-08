#!/usr/bin/perl -wT

BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }

use libsetup;
use libtmcc;
use libvnode_blockstore;
use Data::Dumper;

# Test FreeNAS list parsing
my @list = libvnode_blockstore::parseFreeNASListing("ist_extent");
print "Dump of FreeNAS ist_extent:\n" . Dumper(@list);

# List off slice info
my $sliceh = libvnode_blockstore::getSliceList();
print "Dump of FreeNAS slices:\n" . Dumper(%$sliceh);

# List off pools
my $pools = libvnode_blockstore::getPoolList();
print "Dump of FreeNAS pools:\n" . Dumper(%$pools);

# Grab and stash away storageconfig stuff for some vnode.
my @sconf;
my $vnodeid = "dboxvm1-1";
libsetup_setvnodeid($vnodeid);
libtmcc::configtmcc("portnum",7778);
die "getstorageconfig($vnodeid): $!"
    if (getstorageconfig(\@sconf));
print "Storageconfig for $vnodeid:\n" . Dumper(@sconf);
