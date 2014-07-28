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
include("profile_defs.php");
$page_title = "My Profiles";

#
# Verify page arguments.
#
$reqargs = RequiredPageArguments("uuid",  PAGEARG_STRING);

#
# Get current user.
#
RedirectSecure();
$this_user = CheckLogin($check_status);
if (!$this_user) {
    RedirectLoginPage();
    exit();
}
SPITHEADER(1);

$profile = Profile::Lookup($uuid);
if (!$profile) {
    SPITUSERERROR("No such profile!");
}
else if ($this_user->uid_idx() != $profile->creator_idx() && !ISADMIN()) {
    SPITUSERERROR("Not enough permission!");
}
$profileid = $profile->profileid();

$query_result =
    DBQueryFatal("select v.*,DATE(v.created) as created ".
		 "  from apt_profile_versions as v ".
		 "where v.profileid='$profileid' ".
		 "order by v.created desc");

echo "<div class='row'>
       <div class='col-lg-12 col-lg-offset-0
                   col-md-12 col-md-offset-0
                   col-sm-12 col-sm-offset-0
                   col-xs-12 col-xs-offset-0'>\n";

echo "  <table class='table table-striped table-condensed'>
         <thead>
          <tr>
           <th>Vers</th>
           <th>Creator</th>
           <th>Description</th>
           <th>Created</th>
           <th>Published</th>
           <th>From</th>
          </tr>
         </thead>
         <tbody>\n";

while ($row = mysql_fetch_array($query_result)) {
    $idx     = $row["profileid"];
    $uuid    = $row["uuid"];
    $version = $row["version"];
    $pversion= $row["parent_version"];
    $name    = $row["name"];
    $pid     = $row["pid"];
    $created = $row["created"];
    $published = $row["published"];
    $public  = $row["public"];
    $listed  = ($row["listed"] ? "Yes" : "No");
    $shared  = $row["shared"];
    $creator = $row["creator"];
    $rspec   = $row["rspec"];
    $desc    = '';

    if ($version == 0) {
	$pversion = " ";
    }
    if (!$published) {
	$published = " ";
    }

    if ($public)
	$privacy = "Public";
    elseif ($shared)
	$privacy = "Shared";
    else
	$privacy = "Private";

    $parsed_xml = simplexml_load_string($rspec);
    if ($parsed_xml &&
	$parsed_xml->rspec_tour && $parsed_xml->rspec_tour->description) {
	$desc = $parsed_xml->rspec_tour->description;
    }

    echo " <tr>
             <td>
             <a href='manage_profile.php?action=edit&uuid=$uuid'>$version</a>
            </td>
            <td>$creator</td>
            <td>$desc</td>
            <td>$created</td>
            <td>$published</td>
            <td style='text-align:center'>
             <a href='manage_profile.php?action=edit&uuid=$uuid'>$pversion</a>
            </td>
           </tr>\n";
}
echo "   </tbody>
        </table>
       </div>
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
                  <div id='showtopo_nopicker' class='jacks'></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>\n";

echo "<script type='text/javascript'>\n";
echo "    window.AJAXURL  = 'server-ajax.php';\n";
echo "</script>\n";
echo "<script src='js/lib/jquery-2.0.3.min.js'></script>\n";
echo "<script src='js/lib/bootstrap.js'></script>\n";
echo "<script src='js/lib/require.js' data-main='js/profile-history'></script>\n";

SPITFOOTER();
?>
