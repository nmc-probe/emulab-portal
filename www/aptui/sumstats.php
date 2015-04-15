<?php
#
# Copyright (c) 2000-2015 University of Utah and the Flux Group.
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
chdir("..");
include("defs.php3");
include_once("geni_defs.php");
chdir("apt");
include("quickvm_sup.php");
include("instance_defs.php");
$page_title = "Summary Stats";

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("showby",   PAGEARG_STRING);
if (!isset($showby)) {
    $showby = "user";
}

#
# Get current user.
#
RedirectSecure();
$this_user = CheckLoginOrRedirect();

if (!ISADMIN()) {
    SPITUSERERROR("You do not have permission to view summary stats");
}
SPITHEADER(1);

echo "<link rel='stylesheet'
            href='css/tablesorter.css'>\n";

function ShowByCreator()
{
    global $urn_mapping, $TBBASE;
    
    $query_result =
        DBQueryFatal("select creator,aggregate_urn,count(creator) as ecount, ".
                     "   sum(physnode_count) as pcount, ".
                     "   truncate(sum(physnode_count * ".
                     "     ((UNIX_TIMESTAMP(destroyed) - ".
                     "       UNIX_TIMESTAMP(created)) / 3600.0)),2) as phours ".
                     "from apt_instance_history ".
                     "group by creator,aggregate_urn");
    #
    # Aggregate the per aggregate rows into a single row per user.
    #
    $uid_array = array();

    while ($row = mysql_fetch_array($query_result)) {
        $uid    = $row["creator"];
        $ecount = $row["ecount"];
        $urn    = $row["aggregate_urn"];
        $cluster= $urn_mapping[$urn];
        $ecount = $row["ecount"];
        $pcount = $row["pcount"];
        $phours = $row["phours"];
    
        if (!array_key_exists($uid, $uid_array)) {
            $uid_array[$uid] = array("ecount" => 0,
                                     "pnodes" => 0,
                                     "phours" => 0,
                                     "Utah"   => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0),
                                     "Wisc"   => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0),
                                     "Clem"   => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0),
                                     "APT"    => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0));
        }
        if ($cluster == "MS" || $cluster == "DDC") {
            next;
        }
        $uid_array[$uid]["ecount"] += $ecount;
        $uid_array[$uid]["pcount"] += $pcount;
        $uid_array[$uid]["phours"] += $phours;
        $uid_array[$uid][$cluster]["ecount"] = $ecount;
        $uid_array[$uid][$cluster]["pcount"] = $pcount;
        $uid_array[$uid][$cluster]["phours"] = $phours;
    }
    echo "<input class='form-control search' type='search' data-column='0'
             id='search_uid' placeholder='Search'>\n";
    echo "  <table class='tablesorter' id='tablesorter_uid'>
         <thead>
          <tr>
           <th rowspan=2>UID</th>
           <th colspan=3>Totals</th>
           <th colspan=3>APT</th>
           <th colspan=3>Utah</th>
           <th colspan=3>Wisc</th>
           <th colspan=3>Clem</th>
          </tr>
          <tr>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>PHours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>PHours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>PHours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>PHours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>PHours</th>
          </tr>
          <tr>
           <th class='filter-false sorter-false'>Totals</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
          </tr>
         </thead>\n";
 echo"   <tfoot>
          <tr>
           <th class='filter-false sorter-false'>Totals</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
          </tr>
         </tfoot>\n";

    foreach ($uid_array as $uid => $ref) {
        $uid = "<a href='$TBBASE/showuser.php3?user=$uid'>$uid</a>";
        
        echo
            "<tr>".
            "<td>$uid</td>".
            "<td>" . $ref["ecount"] . "</td> ".
            "<td>" . $ref["pcount"] . "</td> ".
            "<td>" . $ref["phours"] . "</td> ".
            "<td>" . $ref["APT"]["ecount"] . "</td> ".
            "<td>" . $ref["APT"]["pcount"] . "</td> ".
            "<td>" . $ref["APT"]["phours"] . "</td> ".
            "<td>" . $ref["Utah"]["ecount"] . "</td> ".
            "<td>" . $ref["Utah"]["pcount"] . "</td> ".
            "<td>" . $ref["Utah"]["phours"] . "</td> ".
            "<td>" . $ref["Wisc"]["ecount"] . "</td> ".
            "<td>" . $ref["Wisc"]["pcount"] . "</td> ".
            "<td>" . $ref["Wisc"]["phours"] . "</td> ".
            "<td>" . $ref["Clem"]["ecount"] . "</td> ".
            "<td>" . $ref["Clem"]["pcount"] . "</td> ".
            "<td>" . $ref["Clem"]["phours"] . "</td> ".
            "</tr>\n";
    }
    echo "</table>";
}

function ShowByProject()
{
    global $urn_mapping, $TBBASE;
    
    $query_result =
        DBQueryFatal("select pid,aggregate_urn,count(pid) as ecount, ".
                     "   sum(physnode_count) as pcount, ".
                     "   truncate(sum(physnode_count * ".
                     "     ((UNIX_TIMESTAMP(destroyed) - ".
                     "       UNIX_TIMESTAMP(created)) / 3600.0)),2) as phours ".
                     "from apt_instance_history ".
                     "group by pid,aggregate_urn");
    #
    # Aggregate the per aggregate rows into a single row per user.
    #
    $pid_array = array();

    while ($row = mysql_fetch_array($query_result)) {
        $pid    = $row["pid"];
        $urn    = $row["aggregate_urn"];
        $cluster= $urn_mapping[$urn];
        $ecount = $row["ecount"];
        $pcount = $row["pcount"];
        $phours = $row["phours"];

        if (!$pid) {
            $pid = "NONE";
        }
    
        if (!array_key_exists($pid, $pid_array)) {
            $pid_array[$pid] = array("ecount" => 0,
                                     "pnodes" => 0,
                                     "phours" => 0,
                                     "Utah"   => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0),
                                     "Wisc"   => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0),
                                     "Clem"   => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0),
                                     "APT"    => array("ecount" => 0,
                                                       "pcount" => 0,
                                                       "phours" => 0));
        }
        if ($cluster == "MS" || $cluster == "DDC") {
            next;
        }
        $pid_array[$pid]["ecount"] += $ecount;
        $pid_array[$pid]["pcount"] += $pcount;
        $pid_array[$pid]["phours"] += $phours;
        $pid_array[$pid][$cluster]["ecount"] = $ecount;
        $pid_array[$pid][$cluster]["pcount"] = $pcount;
        $pid_array[$pid][$cluster]["phours"] = $phours;
    }
    echo "<input class='form-control search' type='search' data-column='0'
             id='search_pid' placeholder='Search'>\n";
    echo "  <table class='tablesorter' id='tablesorter_pid'>
         <thead>
          <tr>
           <th rowspan=2>PID</th>
           <th colspan=3>Totals</th>
           <th colspan=3>APT</th>
           <th colspan=3>Utah</th>
           <th colspan=3>Wisc</th>
           <th colspan=3>Clem</th>
          </tr>
          <tr>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>Phours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>Phours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>Phours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>Phours</th>
           <th>Expt</th>
           <th>Pnodes</th>
           <th>Phours</th>
          </tr>
          <tr>
           <th class='filter-false sorter-false'>Totals</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
          </tr>
         </thead>\n";
 echo"   <tfoot>
          <tr>
           <th class='filter-false sorter-false'>Totals</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' data-math='col-sum'>0</th>
           <th class='filter-false sorter-false' 
                  data-math='col-sum' data-math-mask='##0.00'>0</th>
          </tr>
         </tfoot>\n";

    foreach ($pid_array as $pid => $ref) {
        if ($pid != "NONE") {
            $pid = "<a href='$TBBASE/showproject.php3?pid=$pid'>$pid</a>";
        }
        echo
            "<tr>".
            "<td>$pid</td>".
            "<td>" . $ref["ecount"] . "</td> ".
            "<td>" . $ref["pcount"] . "</td> ".
            "<td>" . $ref["phours"] . "</td> ".
            "<td>" . $ref["APT"]["ecount"] . "</td> ".
            "<td>" . $ref["APT"]["pcount"] . "</td> ".
            "<td>" . $ref["APT"]["phours"] . "</td> ".
            "<td>" . $ref["Utah"]["ecount"] . "</td> ".
            "<td>" . $ref["Utah"]["pcount"] . "</td> ".
            "<td>" . $ref["Utah"]["phours"] . "</td> ".
            "<td>" . $ref["Wisc"]["ecount"] . "</td> ".
            "<td>" . $ref["Wisc"]["pcount"] . "</td> ".
            "<td>" . $ref["Wisc"]["phours"] . "</td> ".
            "<td>" . $ref["Clem"]["ecount"] . "</td> ".
            "<td>" . $ref["Clem"]["pcount"] . "</td> ".
            "<td>" . $ref["Clem"]["phours"] . "</td> ".
            "</tr>\n";
    }
    echo "</table>";
}
echo "<div class='row'>
        <div class='col-lg-12 col-lg-offset-0
                    col-md-12 col-md-offset-0
                    col-sm-12 col-sm-offset-0
                    col-xs-12 col-xs-offset-0'>\n";

if ($showby == "user") {
    echo "<a href='sumstats.php?showby=project'>Show project stats</a><br>\n"; 
    ShowByCreator();
}
else {
    echo "<a href='sumstats.php?showby=user'>Show user stats</a><br>\n"; 
    ShowByProject();
}
echo " </div>
      </div>\n";

echo "<script src='js/lib/jquery-2.0.3.min.js'></script>\n";
echo "<script src='js/lib/jquery.tablesorter.min.js'></script>\n";
echo "<script src='js/lib/jquery.tablesorter.widgets.min.js'></script>\n";
echo "<script src='js/lib/jquery.tablesorter.widget-math.js'></script>\n";
echo "<script src='js/lib/bootstrap.js'></script>\n";
echo "<script src='js/lib/require.js' data-main='js/sumstats'></script>\n";

SPITFOOTER();
?>
