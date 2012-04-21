<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2012 University of Utah and the Flux Group.
# All rights reserved.
#
include("defs.php3");
include_once("node_defs.php");

#
# Only known and logged in users can do this.
#
$this_user = CheckLoginOrDie();
$uid       = $this_user->uid();
$isadmin   = ISADMIN();

if (! ($isadmin || OPSGUY() || STUDLY())) {
    USERERROR("Cannot view node history.", 1);
}

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("showall",   PAGEARG_BOOLEAN,
				 "reverse",   PAGEARG_BOOLEAN,
				 "count",     PAGEARG_INTEGER,
				 "datetime",  PAGEARG_STRING,
				 "IP",        PAGEARG_STRING,
				 "node",      PAGEARG_NODE);

#
# Standard Testbed Header
#
PAGEHEADER("Node History");

if (!isset($showall)) {
    $showall = 0;
}
if (!isset($count)) {
    $count = 20;
}
if (!isset($reverse)) {
    $reverse = 1;
}
if (!isset($datetime)) {
    $datetime = "";
}
if (isset($IP)) {
    if (! preg_match('/^[0-9\.]+$/', $IP)) {    
	USERERROR("Does not look like a valid IP address.", 1);
    }
    $node = Node::LookupByIP($IP);
    #
    # No record might mean the node does not exist, or that it
    # is a virtual node. We are going to pass IP through to the
    # backend in either case.
    #
    if ($node && $node->isremotenode()) {
	unset($node);
    }
}
$node_id  = (isset($node) ? $node->node_id() : "");
$node_opt = (isset($node) ? "&node_id=$node_id" : "");

$opts="count=$count&reverse=$reverse$node_opt";
echo "<b>Show records:</b> ";
if ($showall) {
    echo "<a href='shownodehistory.php3?$opts'>allocated only</a>,
          all";
} else {
    echo "allocated only,
          <a href='shownodehistory.php3?$opts&showall=1'>all</a>";
}

$opts="count=$count&showall=$showall$node_opt";
echo "<br><b>Order by:</b> ";
if ($reverse == 0) {
    echo "<a href='shownodehistory.php3?$opts&reverse=1'>lastest first</a>,
          earliest first";
} else {
    echo "lastest first,
          <a href='shownodehistory.php3?$opts&reverse=0'>earliest first</a>";
}

$opts="showall=$showall&reverse=$reverse$node_opt";
echo "<br><b>Show number:</b> ";
if ($count != 20) {
    echo "<a href='shownodehistory.php3?$opts&count=20'>first 20</a>, ";
} else {
    echo "first 20, ";
}
if ($count != -20) {
    echo "<a href='shownodehistory.php3?$opts&count=-20'>last 20</a>, ";
} else {
    echo "last 20, ";
}
if ($count != 0) {
    echo "<a href='shownodehistory.php3?$opts&count=0'>all</a>";
} else {
    echo "all";
}

#
# Spit out a date form.
#
if ($datetime == "") {
    $datetime = "mm/dd/yy HH:MM";
}
# Only display search form for a specific node.
if ($node_id != "") {
    echo "<br>";
    echo "<form action=shownodehistory.php3?$opts method=post>
      <b>Show Datetime:</b> 
      <input type=text
             name=datetime
             size=20
             value=\"$datetime\">
      <b><input type=submit name=search value=Search></b>\n";
    echo "</form><br><br>\n";
}

if ($node_id != "" && $datetime != "" && $datetime != "mm/dd/yy HH:MM") {
    if (strtotime($datetime)) {
	ShowNodeHistory($node, 1, 1, 0, $datetime, $IP);
    }
    else {
	USERERROR("Invalid date specified", 1);
    }
}
else {
    ShowNodeHistory((isset($node) ? $node : null),
		    $showall, $count, $reverse, null, $IP);
}

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
