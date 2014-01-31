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
				 "formfields",  PAGEARG_ARRAY);

#
# Spit the form
#
function SPITFORM($formfields, $errors)
{
    global $this_user, $projlist;

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

    $formatter = function($field, $label, $html, $help = null) use ($errors) {
	$class = "form-group";
	if ($errors && array_key_exists($field, $errors)) {
	    $class .= " has-error";
	}
	echo "<div class='$class'>\n";
	echo "  <label for='$field' ".
	"         class='col-sm-3 control-label'>$label ";
	if ($help) {
	    echo "<a href='#' data-toggle='tooltip' title='$help'>".
		"<span class='glyphicon glyphicon-question-sign'></span></a>";
	}
	echo "  </label>\n";
	echo "  <div class='col-sm-7'>\n";
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

    #
    # Look for non-specific error.
    #
    if ($errors && array_key_exists("error", $errors)) {
	echo "<font color=red>" . $errors["error"] . "</font>";
    }

    $formatter("profile_name", "Profile Name",
	       "<input name=\"formfields[profile_name]\"
		       id='profile_name'
		       value='" . $formfields["profile_name"] . "'
                       class='form-control'
                       placeholder='' type='text'>",
	       "alphanumeric, dash, underscore, no whitespace");
    #
    # If user is a member of only one project, then just pass it
    # through, no need for the user to see it. Otherwise we have
    # to let the user choose.
    #
    if (count($projlist) == 1) {
	echo "<input type='hidden' name='formfields[profile_pid]' ".
	    "value='" . $projlist[0] . "'>\n";
    }
    else {
	$pid_options = "";
	while (list($project) = each($projlist)) {
	    $selected = "";
	    if ($formfields["profile_pid"] == $project) {
		$selected = "selected";
	    }
	    $pid_options .= 
		"<option $selected value='$project'>$project</option>\n";
	}
	$formatter("profile_pid", "Project",
		   "<select name=\"formfields[profile_pid]\"
		            id='profile_pid' class='form-control'
                            placeholder='Please Select'>$pid_options</select>");
    }
       
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

    $formatter("profile_public", "Public?",
	       "<div class='checkbox'>
                <label><input name=\"formfields[profile_public]\" ".
	               $formfields["profile_public"] .
	       "       id='profile_public' value=checked
                       type=checkbox> ".
	       "List on the public page for anyone to use?</label></div>");

    echo "      </fieldset>\n";

    echo "<div class='form-group'>
            <div class='col-sm-offset-2 col-sm-10'>
               <button class='btn btn-primary btm-sm pull-right'
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
    
    echo "<script src='js/lib/require.js' data-main='js/manage_profile'></script>";
    SPITFOOTER();
}

#
# The user must be logged in.
#
if (!$this_user) {
    if (isset($formfields)) {
	$_SESSION["formfields"] = $formfields;
    }
    RedirectLoginPage();
    exit();
}

#
# See what projects the user can do this in.
#
$projlist = $this_user->ProjectAccessList($TB_PROJECT_MAKEIMAGEID);

if (! isset($create)) {
    $errors = array();
    
    if (isset($_SESSION["formfields"])) {
	$defaults = $_SESSION["formfields"];
    }
    else {
	$defaults = array();
    }
    if (! (isset($projlist) && count($projlist))) {
	$errors["error"] =
	    "You do not appear to be a member of any projects in which ".
	    "you have permission to create new profiles";
    }
    SPITFORM($defaults, $errors);
    return;
}

#
# Otherwise, must validate and redisplay if errors
#
$errors = array();

#
# Quick check for required fields.
#
$required = array("pid", "name", "description");
		  
foreach ($required as $key) {
    if (!isset($formfields["profile_${key}"]) ||
	strcmp($formfields["profile_${key}"], "") == 0) {
	$errors["profile_${key}"] = "Missing Field";
    }
    elseif (! TBcheck_dbslot($formfields["profile_${key}"], "apt_profiles", $key,
			     TBDB_CHECKDBSLOT_WARN|TBDB_CHECKDBSLOT_ERROR)) {
	$errors["profile_${key}"] = TBFieldErrorString();
    }
}

#
# The rspec has to be treated specially of course.
#
if (isset($_FILES['rspecfile']) &&
    $_FILES['rspecfile']['name'] != "" &&
    $_FILES['rspecfile']['name'] != "none") {

    $rspec = file_get_contents($_FILES['rspecfile']['tmp_name']);
    if (!$rspec) {
	$errors["rspecfile"] = "Could not process file";
    }
    elseif (! TBvalid_html_fulltext($rspec)) {
	$errors["rspecfile"] = TBFieldErrorString();	
    }
}
else {
    $errors["rspecfile"] = "Missing Field";
}

#
# Project has to exist. We need to know it for the SUEXEC call
# below. 
#
$project = Project::LookupByPid($formfields["profile_pid"]);
if (!$project) {
    $errors["profile_pid"] = "No such project";
}

# Present these errors before we call out to do anything else.
if (count($errors)) {
    SPITFORM($formfields, $errors);
    return;
}

#
# Pass to the backend as an XML data file. If this gets too complicated,
# we might eed to do all the checking in the backend and have it pass
# back the error set. 
#
# Generate a temporary file and write in the XML goo.
#
$xmlname = tempnam("/tmp", "newprofile");
if (! $xmlname) {
    TBERROR("Could not create temporary filename", 0);
    $errors["error"] = "Internal error; Could not create temp file";
}
elseif (! ($fp = fopen($xmlname, "w"))) {
    TBERROR("Could not open temp file $xmlname", 0);
    $errors["error"] = "Internal error; Could not open temp file";
}
else {
    fwrite($fp, "<profile>\n");
    fwrite($fp, "<attribute name='profile_pid'>");
    fwrite($fp, "  <value>" . $formfields["profile_pid"] . "</value>");
    fwrite($fp, "</attribute>\n");
    fwrite($fp, "<attribute name='profile_name'>");
    fwrite($fp, "  <value>" .
	   htmlspecialchars($formfields["profile_name"]) . "</value>");
    fwrite($fp, "</attribute>\n");
    fwrite($fp, "<attribute name='profile_description'>");
    fwrite($fp, "  <value>" .
	   htmlspecialchars($formfields["profile_description"]) . "</value>");
    fwrite($fp, "</attribute>\n");
    fwrite($fp, "<attribute name='rspec'>");
    fwrite($fp, "  <value>" . htmlspecialchars($rspec) . "</value>");
    fwrite($fp, "</attribute>\n");
    if (isset($formfields["profile_public"]) &&
	$formfields["profile_public"] == "checked") {
	fwrite($fp, "<attribute name='profile_public'>");
	fwrite($fp, "  <value>1</value>");
	fwrite($fp, "</attribute>\n");
    }
    fwrite($fp, "</profile>\n");
    fclose($fp);
    chmod($xmlname, 0666);
}
if (count($errors)) {
    unlink($xmlname);
    SPITFORM($formfields, $errors);
    return;
}

#
# Call out to the backend.
#
$retval = SUEXEC($this_user->uid(), $project->unix_gid(),
		 "webmanage_profile $xmlname",
		 SUEXEC_ACTION_IGNORE);
if ($retval) {
    if ($retval < 0) {
	$errors["error"] = "Internal Error; please try again later.";
	SUEXECERROR(SUEXEC_ACTION_CONTINUE);
    }
    else {
	#
	# Decode simple XML that is returned. 
	#
	$parsed = simplexml_load_string($suexec_output);
	if (!$parsed) {
	    $errors["error"] = "Internal Error; please try again later.";
	    TBERROR("Could not parse XML output:\n$suexec_output\n", 0);
	}
	else {
	    foreach ($parsed->error as $error) {
		$errors[(string)$error['name']] = $error;
	    }
	}
    }
}
if (count($errors)) {
    unlink($xmlname);
    SPITFORM($formfields, $errors);
    return;
}
header("Location: $APTBASE/quickvm.php");

?>
