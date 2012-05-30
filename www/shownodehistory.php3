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
				 # To allow for pcvm search, since they are
                                 # transient and will not map to a node.
				 "node_id",   PAGEARG_STRING);

#
# Standard Testbed Header
#
PAGEHEADER("Node History");

if (!isset($showall)) {
    $showall = 0;
}
if (!isset($count)) {
    $count = 200;
}
if (!isset($reverse)) {
    $reverse = 1;
}
if (isset($datetime) && $datetime != "") {
    if (! strtotime($datetime)) {
	USERERROR("Invalid date specified", 1);
    }
    $dateopt = "&datetime=" . urlencode($datetime);
}
else {
    $dateopt  = "";
    $datetime = null;
}
if (isset($IP)) {
    if (! preg_match('/^[0-9\.]+$/', $IP)) {    
	USERERROR("Does not look like a valid IP address.", 1);
    }
    $node = Node::LookupByIP($IP);

    #
    # Switch to a node_id if its a physical node. Otherwise, 
    # continue with the IP.
    #
    if ($node && !$node->IsVirtNode()) {
	$node_id = $node->node_id();
	$IP = null;
    }
}
else {
    $IP = null;
}
if (isset($node_id)) {
    $node_opt = "&node_id=$node_id";
    $form_opt = "<input type=hidden name=node_id value=$node_id>";
    $IP      = null;
}
else if (isset($IP)) {
    $node_opt = "&IP=$IP";
    $form_opt = "<input type=hidden name=IP value=$IP>";
    $node_id = null;
}
else {
    $node_opt = "";
    $form_opt = "";
    $IP      = null;
    $node_id = null;
}

$opts="count=$count&reverse=$reverse$node_opt$dateopt";
echo "<b>Show records:</b> ";
if ($showall) {
    echo "<a href='shownodehistory.php3?$opts'>allocated only</a>,
          all";
} else {
    echo "allocated only,
          <a href='shownodehistory.php3?$opts&showall=1'>all</a>";
}

$opts="count=$count&showall=$showall$node_opt$dateopt";
echo "<br><b>Order by:</b> ";
if ($reverse == 0) {
    echo "<a href='shownodehistory.php3?$opts&reverse=1'>lastest first</a>,
          earliest first";
} else {
    echo "lastest first,
          <a href='shownodehistory.php3?$opts&reverse=0'>earliest first</a>";
}

$opts="showall=$showall&reverse=$reverse$node_opt$dateopt";
echo "<br><b>Show number:</b> ";
if ($count != 200) {
    echo "<a href='shownodehistory.php3?$opts&count=200'>first 200</a>, ";
} else {
    echo "first 200, ";
}
if ($count != -200) {
    echo "<a href='shownodehistory.php3?$opts&count=-200'>last 200</a>, ";
} else {
    echo "last 200, ";
}
if ($count != 0) {
    echo "<a href='shownodehistory.php3?$opts&count=0'>all</a>";
} else {
    echo "all";
}

#
# Spit out the various search forms.
#
echo "<br>";
echo "<table class=stealth>\n";
echo "<tr><form action=shownodehistory.php3 method=get>
      <td class=stealth><b>Show Datetime:</b> 
      <input type=text style=\"float:right\"
             name=datetime
             size=20 
             value=\"" . ($datetime ? $datetime : "mm/dd/yy HH:MM") . "\"></td>
      <input type=hidden name=showall value=$showall>
      <input type=hidden name=reverse value=$reverse>
      $form_opt
      <td class=stealth>
        <b><input type=submit name=search1 value=Search></b></td>\n";
echo "</form></tr>\n";
echo "<tr><form action=shownodehistory.php3 method=get>
      <td class=stealth><b>Search for Node:</b> 
      <input type=text align=right
             name=node_id
             size=20
             value=\"$node_id\"></td>
      <input type=hidden name=showall value=$showall>
      <input type=hidden name=reverse value=$reverse>
      <td class=stealth>
       <b><input type=submit name=search2 value=Search></b></td>\n";
    echo "</form></tr>\n";
echo "<tr><form action=shownodehistory.php3 method=get>
      <td class=stealth><b>Search for IP:</b> 
      <input type=text style=\"float:right\"
             name=IP
             size=20
             value=\"$IP\"></td>
      <input type=hidden name=showall value=$showall>
      <input type=hidden name=reverse value=$reverse>
      <td class=stealth>
         <b><input type=submit name=search3 value=Search></b></td>\n";
    echo "</form></tr>\n";
echo "</table><br>\n";

ShowNodeHistory($node_id, $showall, $count, $reverse, $datetime, $IP);

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
