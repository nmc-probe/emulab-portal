use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::LibXML::NodeList;
use Carp qw(cluck carp);


# ip file should be newline-separated ip addresses that are assigned in
# order to pc1, pc2, pc3, etc.

if (scalar(@ARGV) != 4) {
    fatal("Usage: rack-new.pl <out-path> <ip-file> <hp-xml> <wiring-file>\n");
}

my $outpath = shift(@ARGV);
my $ipfile = shift(@ARGV);
my $hpfile = shift(@ARGV);
my $wiringfile = shift(@ARGV);

system("mkdir -p $outpath");

# Load IP data
open(IP, "<$ipfile");
my @iplist = <IP>;
my %control_ips = {};
my %ilo_ips = {};
foreach my $line (@iplist) {
    my @fields = split(/ /, $line);
    my $node_id = $fields[0];
    my $control = $fields[1];
    my $ilo = $fields[2];
    $control_ips{$node_id} = $control;
    $ilo_ips{$node_id} = $ilo;
}
close(IP);

my %devices = ();

# Load node data
my $hpdoc = XML::LibXML->load_xml( location => $hpfile );
foreach my $node ($hpdoc->documentElement()->find("Device")->get_nodelist()) {
    my @maclist = ();
    push(@maclist, GetText("nic1mac", $node));
    push(@maclist, GetText("nic2mac", $node));
    push(@maclist, GetText("nic3mac", $node));
    push(@maclist, GetText("nic4mac", $node));
    my $blob = {
	'location' => GetText("u_location", $node),
	'ilomac' => GetText("lo_mac", $node),
	'maclist' => \@maclist
    };
    if ($blob->{'location'} ne "n/a" &&
	$blob->{'location'} ne "U34") {
	$devices{$blob->{'location'}} = $blob;
    }
}

my @wires = ();

# Load wires/interfaces data
my $wiringdoc = XML::LibXML->load_xml( location => $wiringfile );
foreach my $node ($wiringdoc->documentElement()->find("./wire")->get_nodelist()) {
    my $node_id = GetText('node_id1', $node);
    my $id;
    if ($node_id =~ /pc([0-9])/) {
	$id = $1;
    }
    my $location = GetText('UXX', $node);
    $devices{$location}->{'id'} = $id;
    $devices{$location}->{'node_id'} = $node_id;

    my $blob = {
	'id' => $id,
	'node_id' => $node_id,
	'location' => $location,
	'iface' => GetText('iface', $node),
	'role' => GetText('role', $node),
	'card' => GetText('card1', $node),
	'port' => GetText('port1', $node),
	'switch' => GetText('node_id2', $node),
	'switch_card' => GetText('card2', $node),
	'switch_port' => GetText('port2', $node),
    };
    push(@wires, $blob);
}

# Print nodes
foreach my $current (values(%devices)) {
    my $id = $current->{'id'};
    my $node_id = $current->{'node_id'};
    if (! exists($control_ips{$node_id})) {
	print STDERR "No IP address for node: $node_id\n";
	next;
    }
    my $ip = $control_ips{$node_id};
    open(NODE_FILE, ">$outpath/node.$node_id");
    print NODE_FILE "<newnode>\n";
    print NODE_FILE "  <attribute name='table'><value>node</value></attribute>\n";
    print NODE_FILE "  <attribute name='command'><value>add</value></attribute>\n";
    if (defined($id)) {
	print NODE_FILE "  <attribute name='id'><value>$id</value></attribute>\n";
    }
    print NODE_FILE "  <attribute name='node_id'><value>$node_id</value></attribute>\n";
    print NODE_FILE "  <attribute name='type'><value>dl360</value></attribute>\n";
    print NODE_FILE "  <attribute name='ip'><value>$ip</value></attribute>\n";
    print NODE_FILE "  <attribute name='identifier'><value>$node_id</value></attribute>\n";
    print NODE_FILE "</newnode>\n";
    close(NODE_FILE);
}

# Print interfaces
foreach my $current (@wires) {
    my $id = $current->{'id'};
    my $node_id = $current->{'node_id'};
    my $card = $current->{'card'};
    my $port = $current->{'port'};
    my $location = $current->{'location'};
    my $device = $devices{$location};
    my $mac;
    my $role = $current->{'role'};
    my $type = "bce";
    if ($role eq "mngmnt") {
	$type = "ilo3";
	$mac = $device->{'ilomac'};
    } else {
	my @maclist = @{ $device->{'maclist'} };
	$mac = $maclist[$card];
    }
    open(IF_FILE, ">$outpath/iface.$node_id.$card.$port");
    print IF_FILE "<newinterface>\n";
    print IF_FILE "  <attribute name='table'><value>interface</value></attribute>\n";
    print IF_FILE "  <attribute name='command'><value>add</value></attribute>\n";
    print IF_FILE "  <attribute name='node_id'><value>$id</value></attribute>\n";
    print IF_FILE "  <attribute name='card'><value>$card</value></attribute>\n";
    print IF_FILE "  <attribute name='port'><value>$port</value></attribute>\n";
    print IF_FILE "  <attribute name='mac'><value>$mac</value></attribute>\n";
    print IF_FILE "  <attribute name='type'><value>$type</value></attribute>\n";
    print IF_FILE "  <attribute name='role'><value>$role</value></attribute>\n";
    print IF_FILE "</newinterface>\n";
    close(IF_FILE);
}

# Print wires
foreach my $current (@wires) {
    my $node_id = $current->{'node_id'};
    my $card = $current->{'card'};
    my $port = $current->{'port'};
    my $switch = $current->{'switch'};
    my $switch_card = $current->{'switch_card'};
    my $switch_port = $current->{'switch_port'};
    my $role = $current->{'role'};
    my $type = "Node";
    if ($role eq "ctrl") {
	$type = "Control";
    } elsif ($role eq "mngmnt") {
	$type = "Management";
    }
    open(WIRE_FILE, ">$outpath/wire.$node_id.$card.$port");
    print WIRE_FILE "<newwire>\n";
    print WIRE_FILE "  <attribute name='table'><value>wire</value></attribute>\n";
    print WIRE_FILE "  <attribute name='command'><value>add</value></attribute>\n";
    print WIRE_FILE "  <attribute name='len'><value>0</value></attribute>\n";
    print WIRE_FILE "  <attribute name='type'><value>$type</value></attribute>\n";
    print WIRE_FILE "  <attribute name='node_id1'><value>$node_id</value></attribute>\n";
    print WIRE_FILE "  <attribute name='card1'><value>$card</value></attribute>\n";
    print WIRE_FILE "  <attribute name='port1'><value>$port</value></attribute>\n";
    print WIRE_FILE "  <attribute name='node_id2'><value>$switch</value></attribute>\n";
    print WIRE_FILE "  <attribute name='card2'><value>$switch_card</value></attribute>\n";
    print WIRE_FILE "  <attribute name='port2'><value>$switch_port</value></attribute>\n";
    print WIRE_FILE "</newwire>\n";
    close(WIRE_FILE);
}

# Get the text contents of a child of a node with a particular
# name. This can be either an attribute or an element.
sub GetText($$)
{
    my ($name, $node) = @_;
    my $result = undef;
    my $child = FindFirst('@n:'.$name, $node);
    if (! defined($child)) {
	$child = FindFirst('@'.$name, $node);
    }
    if (! defined($child)) {
	$child = FindFirst('n:'.$name, $node);
    }
    if (defined($child)) {
	$result = $child->textContent();
    }
    return $result;
}

# Returns the first Node which matches a given XPath.
sub FindFirst($$)
{
    my ($path, $node) = @_;
    return FindNodes($path, $node)->pop();
}

# Returns a NodeList for a given XPath using a given node as
# context. 'n' is defined to be the prefix for the namespace of the
# node.
sub FindNodes($$)
{
    my ($path, $node) = @_;
    my $result = undef;
    my $ns = undef;
    eval {
	my $xc = XML::LibXML::XPathContext->new();
	$ns = $node->namespaceURI();
	if (defined($ns)) {
	    $xc->registerNs('n', $ns);
	} else {
	    $path =~ s/\bn://g;
	}
	$result = $xc->findnodes($path, $node);
    };
    if ($@) {
	if (! defined($ns)) {
	    $ns = "undefined";
	}
        cluck "Failed to find nodes using XPath path='$path', ns='$ns': $@\n";
	return XML::LibXML::NodeList->new();
    } else {
	return $result;
    }
}

