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

#
# Get current user.
#
$this_user = CheckLogin($check_status);

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("create",      PAGEARG_STRING,
				 "profile",     PAGEARG_STRING,
				 "formfields",  PAGEARG_ARRAY);

#
# Spit the form
#
function SPITFORM($formfields, $needlogin, $errors)
{
    global $this_user;

    # XSS prevention.
    while (list ($key, $val) = each ($formfields)) {
	$formfields[$key] = CleanString($val);
    }
    # XSS prevention.
    if ($errors) {
	while (list ($key, $val) = each ($errors)) {
	    $errors[$key] = CleanString($val);
	}
    }

    $formatter = function($field, $label, $html) use ($errors) {
	$class = "form-group";
	if ($errors && array_key_exists($field, $errors)) {
	    $class .= " has-error";
	}
	echo "<div class='$class'>\n";
	echo "  <label for='$field' ".
	"         class='col-sm-2 control-label'>$label</label>\n";
	echo "  <div class='col-sm-10'>\n";
	echo "     $html\n";
	if ($errors && array_key_exists($field, $errors)) {
	    echo "<label class='control-label' for='inputError'>" .
		$errors[$field] . "</label>\n";
	}
	echo "  </div>\n";
	echo "</div>\n";
    };

    SPITHEADER(1);

    echo "<div class='row'>
           <div class='col-lg-8  col-lg-offset-2
                       col-md-10 col-md-offset-1
                       col-sm-10 col-sm-offset-1
                       col-xs-12'>\n";
    echo "  <div class='panel panel-default'>
             <div class='panel-heading'>
              <h3 class='panel-title'>
                Create Profile
              </h3>
             </div>
             <div class='panel-body'>\n";
    echo "   <form id='quickvm_create_profile_form'
                   class='form-horizontal' role='form'
                   enctype='multipart/form-data'
                   method='post' action='manage_profile.php'>\n";
    echo "    <div class='row'>\n";
    echo "     <div class='col-sm-12'>\n";
    echo "      <fieldset>\n";


    $formatter("profile_name", "Profile Name",
	       "<input name=\"formfields[profile_name]\"
		       id='profile_name'
		       value='" . $formfields["profile_name"] . "'
                       class='form-control'
                       placeholder='' type='text'>");
    $formatter("profile_description", "Description",
	       "<textarea name=\"formfields[profile_description]\"
		          id='profile_description'
		          rows=4
                          class='form-control'
                          placeholder=''
                          type='textarea'>" .
		    $formfields["profile_description"] . "</textarea>");
    $formatter("rspecfile", "Your rspec",
	       "<input name='rspecfile' id='rspecfile'
                       type=file class='form-control'>");

    echo "      </fieldset>\n";

    echo "<div class='form-group'>
            <div class='col-sm-offset-2 col-sm-10'>
               <button class='btn btn-primary btm-sm'
                   id='profile_submit_button'
                   type='submit' name='create'>Create</button>
            </div>
          </div>\n";
    
    echo "     </div>\n";
    echo "    </div>\n";
    echo "   </form></div>\n";
    echo "  </div>\n";
    echo " </div>\n";
    echo "</div>\n";

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
                     <div id='showtopo_div'></div>
                    </div>
                 </div>
               </div>
            </div>
          </div>
          </div>\n";
    
    echo "<script type='text/javascript'>\n";
    echo "window.APT_OPTIONS = {\n";
    echo "  pageType: 'manage_profile',\n";
    echo "};\n";
    echo "</script>\n";
    
    SPITFOOTER();
}
#
# If not clicked, then put up a form. We use a session variable to
# save the form data in case we have to force the user to login.
#
session_start();

if (! isset($create)) {
    if (isset($_SESSION["formfields"])) {
	$defaults = $_SESSION["formfields"];
    }
    else {
	$defaults = array();
    }

    SPITFORM($defaults, 0, null);
    return;
}

#
# The user must be logged in.
#
if (!$this_user) {
    if (isset($formfields)) {
	$_SESSION["formfields"] = $formfields;
    }
    header("Location: login.php?refer=1");
    # Use exit because of the session. 
    exit();
}
# No longer needed, the user is logged in. 
session_destroy();

SPITFORM($formfields, 0, null);

?>
