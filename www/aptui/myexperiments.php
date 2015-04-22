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
include_once("profile_defs.php");
include_once("instance_defs.php");
$page_title = "My Experiments";
$dblink = GetDBLink("sa");

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("target_user",   PAGEARG_USER,
				 "all",           PAGEARG_BOOLEAN);
if (!isset($all)) {
    $all = 0;
}
#
# Get current user.
#
RedirectSecure();
$this_user = CheckLoginOrRedirect();

if (!isset($target_user)) {
    $target_user = $this_user;
}
if (!$this_user->SameUser($target_user)) {
    if (!ISADMIN()) {
	SPITUSERERROR("You do not have permission to view ".
		      "target user's profiles");
	exit();
    }
}
$target_idx  = $target_user->uid_idx();
$target_uuid = $target_user->uuid();

SPITHEADER(1);

echo "<link rel='stylesheet'
            href='css/tablesorter.css'>\n";

$query_result1 = null;
$query_result2 = null;

if ($all && ISADMIN()) {
    $query_result1 = 
        DBQueryFatal("select a.*,s.expires,s.hrn,u.email, ".
                     " (UNIX_TIMESTAMP(now()) > ".
                     "  UNIX_TIMESTAMP(s.expires)) as expired, ".
                     "  truncate(a.physnode_count * ".
                     "   ((UNIX_TIMESTAMP(now()) - ".
                     "     UNIX_TIMESTAMP(a.created)) / 3600.0),2) as phours ".
                     "  from apt_instances as a ".
                     "left join geni.geni_slices as s on ".
                     "     s.uuid=a.slice_uuid ".
                     "left join geni.geni_users as u on u.uuid=a.creator_uuid ".
                     "order by a.creator");
}
else {
    $query_result1 =
        DBQueryFatal("select a.*,s.expires,s.hrn,u.email, ".
                     " (UNIX_TIMESTAMP(now()) > ".
                     "  UNIX_TIMESTAMP(s.expires)) as expired, ".
                     "  truncate(a.physnode_count * ".
                     "   ((UNIX_TIMESTAMP(now()) - ".
                     "     UNIX_TIMESTAMP(a.created)) / 3600.0),2) as phours ".
                     "  from apt_instances as a ".
                     "left join geni.geni_slices as s on ".
                     "     s.uuid=a.slice_uuid ".
                     "left join geni.geni_users as u on u.uuid=a.creator_uuid ".
                     "where a.creator_uuid='$target_uuid'");

    $query_result2 =
        DBQueryFatal("select distinct a.*,s.expires,s.hrn,u.email, ".
                     " (UNIX_TIMESTAMP(now()) > ".
                     "  UNIX_TIMESTAMP(s.expires)) as expired, ".
                     "  truncate(a.physnode_count * ".
                     "   ((UNIX_TIMESTAMP(now()) - ".
                     "     UNIX_TIMESTAMP(a.created)) / 3600.0),2) as phours ".
                     "  from apt_instances as a ".
                     "left join geni.geni_slices as s on ".
                     "     s.uuid=a.slice_uuid ".
                     "left join geni.geni_users as u on u.uuid=a.creator_uuid ".
                     "left join group_membership as g on ".
                     "     g.uid_idx='$target_idx' and  ".
                     "     g.pid_idx=a.pid_idx ".
                     "where a.creator_uuid='$target_uuid' or ".
                     "      g.uid_idx is not null ".
                     "order by a.creator");
}

function SPITROWS($all, $name, $result)
{
    global $TBBASE, $urn_mapping;
    
    echo "<input class='form-control search' type='search' data-column='all'
             id='experiment_search_${name}' placeholder='Search'>\n";

    echo "  <table class='tablesorter' id='tablesorter_${name}'>
         <thead>
          <tr>
           <th>Profile</th>\n";
        
    if (ISADMIN()) {
        echo " <th>Slice</th>";
    }
    if ($all) {
        echo "     <th>Creator</th>\n";
    }
    echo "     <th>Project</th>
               <th>Status</th>
               <th>Cluster</th>
               <th>PCs</th>
               <th>PHours<b>[1]</b></th>
               <th>VMs</th>\n";
    echo "     <th>Created</th>
               <th>Expires</th>
               </tr>
             </thead>
         <tbody>\n";
    
    while ($row = mysql_fetch_array($result)) {
        $profile_id   = $row["profile_id"];
        $version      = $row["profile_version"];
        $uuid         = $row["uuid"];
        $status       = $row["status"];
        $created      = DateStringGMT($row["created"]);
        $expires      = DateStringGMT($row["expires"]);
        $creator_idx  = $row["creator_idx"];
        $profile_name = $profile_id;
        $creator_uid  = $row["creator"];
        $pid          = $row["pid"];
        $urn          = $row["aggregate_urn"];
        $cluster      = $urn_mapping[$urn];
        $pcount       = $row["physnode_count"];
        $vcount       = $row["virtnode_count"];
        $lockdown     = $row["admin_lockdown"] || $row["user_lockdown"] ? 1 : 0;
        $phours       = $row["phours"];
        list($foo,$hrn) = preg_split("/\./", $row["hrn"]);
        $email        = $row["email"];
        # If a guest user, use email instead.
        if (isset($email)) {
            $creator = $email;
        }
        elseif (ISADMIN()) {
            $creator = "<a href='$TBBASE/showuser.php3?user=$creator_idx'>".
                "$creator_uid</a>";
        }
        else {
            $creator = $creator_uid;
        }
        if ($row["expired"]) {
            $status = "expired";
        }

        $profile = Profile::Lookup($profile_id, $version);
        if ($profile) {
            $profile_name = $profile->name();
        }

        echo " <tr>
            <td>
             <a href='status.php?uuid=$uuid'>$profile_name</a>
            </td>";
        if (ISADMIN()) {
            echo "<td>$hrn</td>";
        }
        if ($all) {
            echo "<td>$creator</td>";
        }
        if (ISADMIN()) {
            echo "  <td><a href='$TBBASE/showproject.php3?pid=$pid'>".
                "$pid</a></td>";
        }
        else {
            echo "  <td>$pid</td>\n";
        }
        echo "  <td>$status</td>\n";
        echo "  <td>$cluster</td>\n";
        echo "  <td>$pcount</td>";
        echo "  <td>$phours</td>";
        echo "  <td>$vcount</td>";
        echo "  <td class='format-date'>$created</td>\n";

        $style = ($lockdown ? "style='color: red;'" : "");
        echo "  <td class='format-date' $style>$expires</td>";
        echo "</tr>\n";
    }
    echo "   </tbody>
        </table>\n";
    echo "[1] <b>PHours</b>: Number of nodes times number of hours in use.<br>";
}

echo "<div class='row'>
        <div class='col-lg-12 col-lg-offset-0
                    col-md-12 col-md-offset-0
                    col-sm-12 col-sm-offset-0
                    col-xs-12 col-xs-offset-0'>\n";

if (mysql_num_rows($query_result1) == 0) {
    $message = "<b>No experiments to show you. Maybe you want to ".
	"<a href='instantiate.php'>start one?</a></b><br>";
    echo $message;
}
else {
    SPITROWS($all, "table1", $query_result1);
}
if ($query_result2 && mysql_num_rows($query_result2)) {
    echo "<br>\n";
    echo "Other experiments in my projects";
    echo "<br>\n";
    SPITROWS(1, "table2", $query_result2);
}

echo " </div>
      </div>\n";

echo "<script src='js/lib/jquery-2.0.3.min.js'></script>\n";
echo "<script src='js/lib/jquery.tablesorter.min.js'></script>\n";
echo "<script src='js/lib/jquery.tablesorter.widgets.min.js'></script>\n";
echo "<script src='js/lib/bootstrap.js'></script>\n";
echo "<script src='js/lib/require.js' data-main='js/myexperiments'></script>\n";

SPITFOOTER();
?>
