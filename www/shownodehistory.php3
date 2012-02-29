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
$node_id = (isset($node) ? $node->node_id() : "");

$opts="node_id=$node_id&count=$count&reverse=$reverse";
echo "<b>Show records:</b> ";
if ($showall) {
    echo "<a href='shownodehistory.php3?$opts'>allocated only</a>,
          all";
} else {
    echo "allocated only,
          <a href='shownodehistory.php3?$opts&showall=1'>all</a>";
}

$opts="node_id=$node_id&count=$count&showall=$showall";
echo "<br><b>Order by:</b> ";
if ($reverse == 0) {
    echo "<a href='shownodehistory.php3?$opts&reverse=1'>lastest first</a>,
          earliest first";
} else {
    echo "lastest first,
          <a href='shownodehistory.php3?$opts&reverse=0'>earliest first</a>";
}

$opts="node_id=$node_id&showall=$showall&reverse=$reverse";
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
	ShowNodeHistory($node, 1, 1, 0, $datetime);
    }
    else {
	USERERROR("Invalid date specified", 1);
    }
}
else {
    ShowNodeHistory((isset($node) ? $node : null), $showall, $count, $reverse);
}

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
