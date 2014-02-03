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
#
# Deal with ajax requests.
#
if (isset($ajax_request)) {
    if ($ajax_method == "getprofile") {
	$profile_idx = addslashes($ajax_argument);
	#
	# XXX This query effectively allows a user to look at another
	# users profile, by cheating the ajax interface. Not a big
	# deal yet, but something to worry about right now.
	#
	$query_result =
	    DBQueryWarn("select * from apt_profiles ".
			"where idx='$profile_idx'");

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

if (isset($target_user) && !$this_user->SameUser($target_user)) {
    if (!ISADMIN()) {
	SPITUSERERROR("You do not have permission to view ".
		      "target user's profiles");
	SPITFOOTER();
	exit();
    }
}
else {
    $target_user = $this_user;
}
$target_idx = $target_user->uid_idx();

$query_result =
    DBQueryFatal("select * from apt_profiles ".
		 "where creator_idx=$target_idx");

if (mysql_num_rows($query_result) == 0) {
    echo "<b>No profiles to show you. Maybe you want to ".
	"<a href='manage_profile.php'>create one?</a></b>\n";
    SPITFOOTER();
    exit();
}
$profile_array  = array();
$profile_default = null;

while ($row = mysql_fetch_array($query_result)) {
    $profile_array[$row["idx"]] = $row["name"];
    if (!$profile_default) {
	$profile_default = $row["idx"];
    }
}

echo "<div class='row'>
       <div class='col-lg-6  col-lg-offset-3
                   col-md-6  col-md-offset-3
                   col-sm-8  col-sm-offset-2
                   col-xs-12 col-xs-offset-0'>\n";
echo "    <div class='panel panel-default'>
            <div class='panel-heading'>
              <h3 class='panel-title'>
                 Your Profiles</h3>
            </div>
            <div class='panel-body'>
             <form id='quickvm_create_profile_form'
                   role='form'
                   method='get' action='manage_profile.php'>
              <input type='hidden' name='action' value='edit'/>
              <div id='profile_well' class='form-group well well-md'>
                <span id='selected_profile_text' class='pull-left'>
                </span>
                <input id='selected_profile' type='hidden' name='idx'/>
                <button id='profile' class='btn btn-primary btn-xs pull-right' 
                       type='button' name='profile_button'>
                  Select a Profile</button>\n";
echo "        </div>
              <button class='btn btn-primary btn-xs pull-right'
                       type='submit' name='submit'>Go</button>
            </form>
           </div>
          </div>
        </div>
       </div>\n";

SpitTopologyViewModal("quickvm_topomodal", $profile_array);

echo "<script type='text/javascript'>\n";
echo "window.PROFILE = '$profile_default';\n";
echo "</script>\n";
echo "<script src='js/lib/require.js' data-main='js/myprofiles'></script>\n";

SPITFOOTER();
?>
