<?php
#
# Copyright (c) 2000-2014 University of Utah and the Flux Group.
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
chdir("apt");
include("quickvm_sup.php");
$page_title = "My Profiles";

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("target_user",   PAGEARG_USER,
				 "all",           PAGEARG_BOOLEAN,
				 "ajax_request",  PAGEARG_BOOLEAN,
				 "ajax_method",   PAGEARG_STRING,
				 "ajax_argument", PAGEARG_STRING);

#
# Get current user.
#
RedirectSecure();
$this_user = CheckLogin($check_status);
if (!$this_user) {
    if (isset($ajax_request)) {
	SPITAJAX_ERROR(1, "You are not logged in anymore");
	exit();
    }
    RedirectLoginPage();
    exit();
}
if (!isset($target_user)) {
    $target_user = $this_user;
}
if (!$this_user->SameUser($target_user)) {
    if (!ISADMIN()) {
	if (isset($ajax_request)) {
	    SPITAJAX_ERROR(1, "You do not have permission to do this");
	}
	else {
	    SPITUSERERROR("You do not have permission to view ".
			  "target user's profiles");
	}
	exit();
    }
}
$target_idx = $target_user->uid_idx();

#
# Deal with ajax requests.
#
if (isset($ajax_request)) {
    if ($ajax_method == "getprofile") {
	$profile_idx = addslashes($ajax_argument);
	$query_result =
	    DBQueryWarn("select * from apt_profiles ".
			"where idx='$profile_idx' and ".
			"      creator_idx='$target_idx'");

	if (!$query_result || !mysql_num_rows($query_result)) {
	    SPITAJAX_ERROR(1, "No such profile $profile_idx!");
	    exit();
	}
	$row = mysql_fetch_array($query_result);
	
	SPITAJAX_RESPONSE(array('rspec' => $row['rspec'],
				'name'  => $row['name'],
				'idx'   => $row['idx'],
				'description' => $row['description']));
    }
    exit();
}

SPITHEADER(1);

echo "<link rel='stylesheet'
            href='tablesorter.css'>\n";

$query_result =
    DBQueryFatal("select *,DATE(created) as created ".
		 "  from apt_profiles ".
		 (isset($all) && ISADMIN() ?
		  "order by creator" : "where creator_idx='$target_idx'"));

if (mysql_num_rows($query_result) == 0) {
    $message = "<b>No profiles to show you. Maybe you want to ".
	"<a href='manage_profile.php'>create one?</a></b><br><br>";

    if (ISADMIN()) {
	$message .= "<img src='/redball.gif'>".
	    "<a href='myprofiles.php?all=1'>Show all user Profile</a>";
    }
    SPITUSERERROR($message);
    exit();
}
echo "<div class='row'>
       <div class='col-lg-12 col-lg-offset-0
                   col-md-12 col-md-offset-0
                   col-sm-12 col-sm-offset-0
                   col-xs-12 col-xs-offset-0'>\n";

echo "<input class='form-control search' type='search'
             id='profile_search' placeholder='Search'>\n";

echo "  <table class='tablesorter'>
         <thead>
          <tr>
           <th>Name</th>\n";
if (isset($all) && ISADMIN()) {
    echo " <th>Creator</th>";
}
echo "     <th>Project</th>
           <th>Description</th>
           <th>Show</th>
           <th>Created</th>
           <th>Public</th>
          </tr>
         </thead>
         <tbody>\n";

while ($row = mysql_fetch_array($query_result)) {
    $idx     = $row["idx"];
    $name    = $row["name"];
    $pid     = $row["pid"];
    $desc    = $row["description"];
    $created = $row["created"];
    $public  = $row["public"];
    $creator = $row["creator"];
    $rspec   = $row["rspec"];;

    $parsed_xml = simplexml_load_string($rspec);
    if ($parsed_xml &&
	$parsed_xml->rspec_tour && $parsed_xml->rspec_tour->description) {
	$desc = $parsed_xml->rspec_tour->description;
    }
    
    echo " <tr>
            <td>
             <a href='manage_profile.php?action=edit&idx=$idx'>$name</a>
            </td>";
    if (isset($all) && ISADMIN()) {
	echo "<td>$creator</td>";
    }
    echo "  <td style='white-space:nowrap'>$pid</td>
            <td>$desc</td>
            <td style='text-align:center'>
             <button class='btn btn-primary btn-xs showtopo_modal_button'
                     data-profile=$idx>
               Show</button>
            </td>
            <td>$created</td>
            <td>$public</td>
           </tr>\n";
}
echo "   </tbody>
        </table>\n";

if (ISADMIN() && !isset($all)) {
    echo "<img src='/redball.gif'>
          <a href='myprofiles.php?all=1'>Show all user Profiles</a>\n";
}
echo"   </div>
      </div>\n";

echo "<!-- This is the topology view modal -->
      <div id='quickvm_topomodal' class='modal fade'>
        <div class='modal-dialog' id='showtopo_dialog'>
          <div class='modal-content'>
            <div class='modal-header'>
              <button type='button' class='close' data-dismiss='modal'
                      aria-hidden='true'>
                      &times;</button>
                <h3>Topology Viewer</h3>
            </div>
            <div class='modal-body'>
              <!-- This topo diagram goes inside this div -->
              <div class='panel panel-default'
                         id='showtopo_container'>
                <div class='panel-body'>
                  <div id='showtopo_nopicker'></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>\n";

echo "<script src='js/lib/require.js' data-main='js/myprofiles'></script>\n";

SPITFOOTER();
?>
