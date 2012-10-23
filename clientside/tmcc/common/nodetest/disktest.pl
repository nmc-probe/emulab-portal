#
# Run a 0.5GB dd every 5GBs on the disk
#
use Getopt::Std;

my $DISKSIZE =  240;	# in GB or 0 to just go to end
my $INTERVAL =   10;	# in GB
my $IOSIZE =    128;	# in MB
my $BLOCKSIZE = 128;	# in KB

my $COUNT = ($IOSIZE*1024) / $BLOCKSIZE;
my $BLKSPERGB = (1024*1024) / $BLOCKSIZE;

my $OS = `uname`;
chomp($OS);

#
# Process command-line arguments
#
my $debug = 0;
my $doit = 1;
my $force = 0;
my $quick = 0;
my $indisk;
my $outdisk;
my %opt = ();
getopts("d:i:o:nfq", \%opt);

if ($opt{'d'}) {
    $debug = $opt{'d'};
}
if ($opt{'n'}) {
    $doit = 0;
}
if ($opt{'i'}) {
    $indisk = $opt{'i'};
}
if ($opt{'o'}) {
    $outdisk = $opt{'o'};
}
if ($opt{'f'}) {
    $force = 1;
}
if ($opt{'q'}) {
    $quick = 1;
}

if (!$indisk && !$outdisk) {
    die("Must specify one of -i or -o");
}
if ($indisk && $outdisk) {
    die("Must specify EXACTLY one of -i or -o");
}
if ($outdisk && !$force) {
    print "Are you SURE you want to write to $outdisk? ";
    my $line = <STDIN>;
    chomp $line;
    if ($line =~ /^yes$/i) {
	print "okay, its your disk...\n";
    } else {
	print "wise choice!\n";
	exit(0);
    }
}

my $gboffset = 0;
my ($inarg, $outarg, $sizearg, $countarg, $skiparg, $xtraarg);

if ($indisk) {
    $inarg = "if=$indisk";
    if ($OS eq "Linux") {
	$xtraarg = "iflag=direct";
    } else {
	$xtraarg = "";
    }
    $outarg = "of=/dev/null";
} else {
    $inarg = "if=/dev/zero";
    $outarg = "of=$outdisk";
    if ($OS eq "Linux") {
	$xtraarg = "oflag=direct";
    } else {
	$xtraarg = "";
    }
}
# note: 'k' means 1024 for both BSD and Linux (gnu) dd
$sizearg = "bs=${BLOCKSIZE}k";
$countarg = "count=$COUNT";

while ($DISKSIZE == 0 || $gboffset < $DISKSIZE) {
    my $off = $gboffset * $BLKSPERGB;
    my $skiparg = $off ? "skip=$off" : "";
    if (!$quick) {
	print "${gboffset}GB: ";
    }
    if ($doit) {
	print STDERR "dd $inarg $outarg $skiparg $sizearg $countarg $xtraarg\n"
	    if ($debug);
	my @output = `dd $inarg $outarg $skiparg $sizearg $countarg $xtraarg 2>&1`;
	my $mbps;
	foreach my $line (@output) {
	    chomp($line);

	    # BSD: 1073741824 bytes transferred in 62.940028 secs (17059761 bytes/sec)
	    if ($line =~ /\((\d+)\s+bytes\/sec\)/) {
		$mbps = $1 / (1000 * 1000);
		print STDERR "Parsed line: '$line'\n"
		    if ($debug > 1);
		last;
	    }
	    # Linux: 1342177280 bytes (1.3 GB) copied, 12.7455 s, 95.5 MB/s
	    # (MB is 1000*1000).
	    if ($line =~ /,\s+(\d+(?:\.\d+)?)\s+MB\/s/) {
		$mbps = $1;
		print STDERR "Parsed line: '$line'\n"
		    if ($debug > 1);
		next;
	    }
	    if ($line =~ /permission denied/i) {
		die($line);
	    }
	    print STDERR "Skipped line: '$line'\n"
		if ($debug > 1);
	}
	printf "%.2f MB/sec ", $mbps;
    } else {
	print "would do dd $inarg $outarg $skiparg $sizearg $countarg\n"
    }
    $gboffset += $INTERVAL;
    last if ($quick);
}

exit(0);
