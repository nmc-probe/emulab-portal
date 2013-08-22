<?php
#
# Copyright (c) 2000-2013 University of Utah and the Flux Group.
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
include("defs.php3");

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
$optargs = OptionalPageArguments("datetime",  PAGEARG_STRING,
				 "record",    PAGEARG_INTEGER,
				 "count",     PAGEARG_INTEGER,
				 "when",      PAGEARG_STRING,
				 "tag",       PAGEARG_INTEGER);

#
# Standard Testbed Header
#
PAGEHEADER("Vlan Tag History");

if (!isset($count)) {
    $count = 200;
}
if (!isset($record) || $record == "") {
    $record = null;
}
if (isset($record)) {
    # Record overrides date/when.
    $dateopt  = "";
    $datetime = null;
    $when     = null;
}
elseif (isset($datetime) && $datetime != "") {
    if (! strtotime($datetime)) {
	USERERROR("Invalid date specified", 1);
    }
    $dateopt = "&datetime=" . urlencode($datetime);
    $record  = null;
}
elseif (isset($when) && $when == "current") {
    $datetime = null;
    $dateopt  = "";
    $record   = null;
}
elseif (isset($when) && $when == "yesterday") {
    $datetime = date("Y-m-d H:i:s", time() - (24 * 3600));
    $dateopt = "&datetime=" . urlencode($datetime);
    $record  = null;
}
elseif (isset($when) && $when == "lastweek") {
    $datetime = date("Y-m-d H:i:s", time() - (7 * 24 * 3600));
    $dateopt = "&datetime=" . urlencode($datetime);
    $record  = null;
}
elseif (isset($when) && $when == "lastmonth") {
    $datetime = date("Y-m-d H:i:s", time() - (30 * 24 * 3600));
    $dateopt = "&datetime=" . urlencode($datetime);
    $record  = null;
}
else {
    $dateopt  = "";
    $datetime = null;
    $when     = "epoch";
}
if (isset($tag)) {
    $tag_opt  = "tag=$tag";
    $form_opt = "<input type=hidden name=tag value=$tag>";
    $IP      = null;
    $mac     = null;
}
else {
    $tag_opt  = "";
    $form_opt = "";
    $tag      = null;
}

$opts="$tag_opt$dateopt";
echo "<br><b>Show:</b> ";
if ($when == "lastmonth") {
    echo "Last Month, ";
}
else {
    echo "<a href='showvlantaghistory.php?$opts&when=lastmonth'>".
	"Last Month</a>, ";
}
if ($when == "lastweek") {
    echo "Last Week, ";
}
else {
    echo "<a href='showvlantaghistory.php?$opts&when=lastweek'>".
	"Last Week</a>, ";
}
if ($when == "yesterday") {
    echo "Yesterday, ";
}
else {
    echo "<a href='showvlantaghistory.php?$opts&when=yesterday'>".
	"Yesterday</a>, ";
}
if ($when == "current") {
    echo "Current, ";
}
else {
    echo "<a href='showvlantaghistory.php?$opts&when=current'>".
	"Current</a>, ";
}
if ($when == "epoch") {
    echo "Epoch";
}
else {
    echo "<a href='showvlantaghistory.php?$opts&when=epoch'>Epoch</a>";
}

#
# Spit out the various search forms.
#
echo "<br>";
echo "<table class=stealth>\n";
echo "<tr><form action=showvlantaghistory.php method=get>
      <td class=stealth><b>Show Datetime:</b></td>
      <td class=stealth><input type=text style=\"float:right\"
             name=datetime
             size=20 
             value=\"" . ($datetime ? $datetime : "mm/dd/yy HH:MM") . "\"></td>
      <input type=hidden name=when    value=$when>
      $tag_opt
      </td><td class=stealth>
        <b><input type=submit name=search1 value=Search></b></td>\n";
echo "</form></tr>\n";
echo "<tr><form action=showvlantaghistory.php method=get>
      <td class=stealth><b>Search for tag:</b></td>
      <td class=stealth><input type=text style=\"float:right\"
             name=tag
             size=6
             value=\"$tag\"></td>
      <input type=hidden name=when    value=$when></td>
      <td class=stealth>
         <b><input type=submit name=search3 value=Search></b></td>\n";
    echo "</form></tr>\n";
echo "</table><br>\n";

#
#
#
if ($when == "current") {
    $clauses = array();
    $clause  = "";

    if ($tag) {
	$clauses[] = "tag='$tag'";
    }
    if ($datetime) {
	$clauses[] = "reserve_time>" . strtotime($datetime);
    }
    if (count($clauses)) {
	$clause = "where " . join(" and ", $clauses);
    }
    
    $query_result =
	DBQueryFatal("select v.*, ".
		     "   reserve_time as allocated ".
		     " from reserved_vlantags as v ".
		     "left join experiment_stats as s on s.exptidx=v.exptidx ".
		     "$clause ".
		     "order by tag desc");
}
else {
    $clauses = array();
    $clause  = "";

    if ($tag) {
	$clauses[] = "tag='$tag'";
    }
    if ($datetime) {
	$clauses[] = "allocated>" . strtotime($datetime);
    }
    if ($record) {
	$clauses[] = "history_id>$record";
    }
    if (count($clauses)) {
	$clause = "where " . join(" and ", $clauses);
    }

    $query_result =
	DBQueryFatal("select v.*,s.pid,s.eid, ".
		     "   from_unixtime(allocated) as allocated, ".
		     "   from_unixtime(released) as released ".
		     " from vlantag_history as v ".
		     "left join experiment_stats as s on s.exptidx=v.exptidx ".
		     "$clause ".
		     "order by history_id limit $count");
}

if (mysql_num_rows($query_result)) {
    $num_records = mysql_num_rows($query_result);
    
    # Keep track of history record bounds, for paging through.
    $max_history_id = 0;

    # Build up table contents.
    $html = "";

    while ($row = mysql_fetch_array($query_result)) {
	$thistag = $row{"tag"};
	$exptidx = $row{"exptidx"};
	$pid     = $row{"pid"};
	$eid     = $row{"eid"};
	$alloc   = $row{"allocated"};
	$lanid   = $row{"lanid"};
	$id      = 0;
	$slice   = "--";

	if (isset($row{"released"})) {
	    $free = $row{"released"};
	}
	else {
	    $free = "&nbsp";
	}
	if (isset($row{"history_id"})) {
	    $id = $row{"history_id"};
	}

	$experiment = Experiment::Lookup($exptidx);
	$experiment_stats = ExperimentStats::Lookup($exptidx);
	if ($experiment_stats &&
	    $experiment_stats->slice_uuid()) {
	    $url = CreateURL("genihistory",
			     "slice_uuid",
			     $experiment_stats->slice_uuid());
	    $slice = "<a href='$url'>" .
		"<img src=\"greenball.gif\" border=0></a>";
	}
	if ($experiment) {
	    $expurl = CreateURL("showexp",
				URLARG_EID, $experiment->idx());
	}
	else {
	    $expurl = CreateURL("showexpstats",
				"record",
				$experiment_stats->exptidx());
	}
	if ($id > $max_history_id)
	    $max_history_id = $id;

	$html .= "<tr>";
	if (!$tag) {
	    $html .= "<td>$thistag</td>";
	}
	$html .= "<td>$lanid</td>";
 	$html .= "<td>$pid</td>";
	if ($expurl) {
	    $html .= "<td><a href='$expurl'>$eid</a></td>";
	}
	else {
	    $html .= "<td>$eid</td>";
	}
	if ($PROTOGENI) {
	    $html .= "<td>$slice</td>";
	}
        $html .= "<td>$alloc</td>
                  <td>$free</td>
                </tr>\n";
    }

    if ($num_records >= $count && $when != "current") {
	echo "<center><a href='showvlantaghistory.php?record=$max_history_id".
	    "&count=$count&$tag_opt'>Next $count records</a></center>\n";
    }
    echo "<table border=1 cellpadding=2 cellspacing=2 align='center'>\n";
    echo "<tr>";
    if (! $tag) {
	echo "<th>Tag</th>";
    }
    echo "<th>Lanid</th>
	  <th>Pid</th>
          <th>Eid</th>";
    if ($PROTOGENI) {
	echo "<th>Slice</th>";
    }
    echo "<th>Allocated</th>
          <th>Released</th>
         </tr>\n";
    echo $html;
    echo "</table>\n";
}

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
