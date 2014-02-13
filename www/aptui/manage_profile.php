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
$page_title = "Manage Profile";
$notifyupdate = 0;

#
# Get current user.
#
$this_user = CheckLogin($check_status);

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("create",      PAGEARG_STRING,
				 "action",      PAGEARG_STRING,
				 "idx",         PAGEARG_INTEGER,
				 "finished",    PAGEARG_BOOLEAN,
				 "formfields",  PAGEARG_ARRAY);

#
# Spit the form
#
function SPITFORM($formfields, $errors)
{
    global $this_user, $projlist, $action, $idx, $notifyupdate;
    $editing = 0;

    if ($action == "edit") {
	$button_label = "Modify";
	$title        = "Modify Profile";
	$editing = 1;
    }
    else  {
	$button_label = "Create";
	$title        = "Create Profile";
    }
    
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
	    echo "<a href='#' class='btn btn-xs'
                     data-toggle='popover' data-content='$help'>".
		"<span class='glyphicon glyphicon-question-sign'></span></a>";
	}
	echo "  </label>\n";
	echo "  <div class='col-sm-9'>\n";
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
              <h3 class='panel-title'>$title</h3>
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
	echo "<font color=red><center>" . $errors["error"] . "</center></font>";
    }
    # Did we just complete an update.
    if ($notifyupdate) {
	echo "<font color=green><center>Update Successful!</center></font>";
    }
    # Mark as editing mode on post.
    if ($editing) {     
	echo "<input type='hidden' name='action' value='edit'>\n";
    }

    # In editing mode, pass through static values.
    if ($editing) {
	$formatter("profile_name", "Profile Name",
		   "<p class='form-control-static'>" .
		       $formfields["profile_name"] .
		   " (created " . $formfields["profile_created"] . ")</p>");
		   
	echo "<input type='hidden' name='formfields[profile_name]' ".
		"value='" . $formfields["profile_name"] . "'>\n";
    }
    else {
	$formatter("profile_name", "Profile Name",
		   "<input name=\"formfields[profile_name]\"
		       id='profile_name'
		       value='" . $formfields["profile_name"] . "'
                       class='form-control'
                       placeholder='' type='text'>",
		   "alphanumeric, dash, underscore, no whitespace");
    }
    #
    # If user is a member of only one project, then just pass it
    # through, no need for the user to see it. Otherwise we have
    # to let the user choose.
    #
    if (count($projlist) == 1 || $editing) {
	$pid = ($editing ? $formfields["profile_pid"] : $projlist[0]);
	
	if ($editing) {
	    $formatter("profile_pid", "Project",
		       "<p class='form-control-static'>$pid</p>");
	}
	echo "<input type='hidden' name='formfields[profile_pid]' ".
		"value='$pid'>\n";
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
		          rows=3
                          class='form-control'
                          placeholder=''
                          type='textarea'>" .
		    $formfields["profile_description"] . "</textarea>");

    #
    # In edit mode, display current rspec in text area inside a modal.
    # See below for the modal. So, we need buttons to display the source
    # modal, the topo modal, in addition to a file chooser for a new rspec.
    #
    if ($editing) {
	$rspec_html =
	         "<div class='row'>
                   <div class='col-xs-2'>
                     <button class='btn btn-primary btn-xs'
                         id='showtopo_modal_button'>
                        Show</button>
                   </div>
                   <div class='col-xs-2'>
                     <button class='btn btn-primary btn-xs' type='button'
                         data-toggle='collapse' data-target='#rspec_textarea'>
                          Edit</button>
                   </div>
                   <div class='col-xs-8'>
                     <input name='rspecfile' id='rspecfile' type=file
                         class='filestyle'
			 data-classButton='btn btn-primary btn-xs'
                         data-input='false' data-buttonText='Choose new file'>
                   </div>
                  </div>
                  <div class='collapse' id='rspec_textarea'
                       style='margin-top: 4px;'>
                   <div class='row'>
                    <div class='col-xs-12'>
 	             <textarea name=\"formfields[profile_rspec]\"
		           id='profile_rspec_textarea'
		           rows=5
                           class='form-control'
                           type='textarea'>" .
		     $formfields["profile_rspec"] . "</textarea>
                    </div>
                   </div>
                   <div class='row' style='margin-top: 4px;'>
                    <div class='col-xs-12'>
                     <button class='btn btn-primary btn-xs' type='button'
                         id='expand_rspec_modal_button'>
                          Expand</button>
                    </div>
                  </div>
                </div>\n";
    }
    else {
	$rspec_html = "<input name='rspecfile' id='rspecfile'
                       type=file class='form-control'>";
    }
    $formatter("profile_rspec", "Your rspec", $rspec_html);

    $formatter("profile_listed", "Listed?",
	       "<div class='checkbox'>
                <label><input name=\"formfields[profile_listed]\" ".
	               $formfields["profile_listed"] .
	       "       id='profile_listed' value=checked
                       type=checkbox> ".
	       "List on the public page for anyone to use?</label></div>");

    if ($editing) {
    	$formatter("profile_url", "Public URL",
		   "<input name=\"formfields[profile_url]\"
		       id='profile_url' readonly
		       value='" . $formfields["profile_url"] . "'
                       class='form-control'
                       placeholder='' type='text'>");
    }
    echo "      </fieldset>\n";

    echo "<div class='form-group'>
            <div class='col-sm-offset-2 col-sm-10'>
               <button class='btn btn-primary btn-sm pull-right'
                   id='profile_submit_button'
                   disabled='disabled'
                   style='margin-right: 10px;'
                   type='submit' name='create'>$button_label</button>\n";
    if ($editing) {
	echo " <a class='btn btn-primary btn-sm pull-right'
                   style='margin-right: 10px;'
                   href='quickvm.php?profile=$idx'
                   type='submit' name='create'>Instantiate</a>\n";
	echo " <a class='btn btn-danger btn-sm pull-left'
                   style='margin-right: 10px;'
                   href='manage_profile.php?action=delete&idx=$idx'
                   type='button' name='delete'>Delete</a>\n";
    }
    echo "  </div>\n";
    echo "</div>\n";
    echo "     </div>\n";
    echo "    </div>\n";

    echo "<!-- This is the rspec text view modal -->
          <div id='rspec_modal' class='modal fade'>
          <div class='modal-dialog'>
            <div class='modal-content'>
               <div class='modal-header'>
                <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>
                   &times;</button>
                <button type='button' class='btn btn-primary btn-xs pull-right'
                   style='margin-right: 10px;'
                   id='collapse_rspec_modal_button'>
                   Collapse</button>
                <h3>rspec XML</h3>
               </div>
               <div class='modal-body'>
                 <div class='panel panel-default'>
                    <div class='panel-body'>
	              <textarea name=\"formfields[profile_rspec_modal]\"
		          id='modal_profile_rspec_textarea'
		          rows=20
                          class='form-control'
                          type='textarea'></textarea>
                    </div>
                 </div>
               </div>
            </div>
          </div>
          </div>\n";
    
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
                     <div id='showtopo_nopicker'></div>
                    </div>
                 </div>
               </div>
            </div>
          </div>
          </div>\n";
    
    echo "<script src='js/lib/require.js' data-main='js/manage_profile'>
          </script>";
    SPITFOOTER();
}

#
# The user must be logged in.
#
if (!$this_user) {
    RedirectLoginPage();
    exit();
}
$this_idx = $this_user->uid_idx();

#
# See what projects the user can do this in.
#
$projlist = $this_user->ProjectAccessList($TB_PROJECT_MAKEIMAGEID);

if (! isset($create)) {
    $errors   = array();
    $defaults = array();
    
    if (! (isset($projlist) && count($projlist))) {
	$errors["error"] =
	    "You do not appear to be a member of any projects in which ".
	    "you have permission to create new profiles";
    }
    if ($action == "edit" || $action == "delete") {
	if (!isset($idx)) {
	    $errors["error"] = "No profile specified for edit/delete!";
	}
	else {
	    $profile = Profile::Lookup($idx);
	    
	    if (!$profile) {
		SPITUSERERROR("No such profile!");
	    }
	    else if ($this_idx != $profile->creator_idx() && !ISADMIN()) {
		SPITUSERERROR("Not enough permission!");
	    }
	    else if ($action == "delete") {
		DBQueryFatal("delete from apt_profiles where idx='$idx'");
		header("Location: $APTBASE/myprofiles.php");
		return;
	    }
	    else {
		$defaults["profile_pid"]         = $profile->pid();
		$defaults["profile_description"] = $profile->description();
		$defaults["profile_name"]        = $profile->name();
		$defaults["profile_rspec"]       = $profile->rspec();
		$defaults["profile_created"]     = $profile->created();
		$defaults["profile_url"]         = $profile->url();
		$defaults["profile_listed"]      =
		    ($profile->listed() ? "checked" : "");

		#
		# If we are displaying after a successful edit, and it
		# just happened (by looking at the modify time), show
		# a message that the update was successful. This is pretty
		# crappy, but I do not want to go for a fancy thing (popover)
		# just yet, maybe later.
		#
		if (isset($finished) && $profile->modified()) {
		    $mod = new DateTime($profile->modified());
		    if ($mod) {
			$now  = new DateTime("now");
			$diff = $now->getTimestamp() - $mod->getTimestamp();
			if ($diff < 2) {
			    $notifyupdate = 1;
			}
		    }
		}
	    }
	}
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
# The rspec file has to be treated specially of course.
#
if (isset($_FILES['rspecfile']) &&
    $_FILES['rspecfile']['name'] != "" &&
    $_FILES['rspecfile']['name'] != "none") {

    $rspec = file_get_contents($_FILES['rspecfile']['tmp_name']);
    if (!$rspec) {
	$errors["profile_rspec"] = "Could not process file";
    }
    elseif (! TBvalid_html_fulltext($rspec)) {
	$errors["profile_rspec"] = TBFieldErrorString();	
    }
}
elseif (isset($formfields["profile_rspec"]) &&
	$formfields["profile_rspec"] != "") {
    if (! TBvalid_html_fulltext($formfields["profile_rspec"])) {
	$errors["profile_rspec"] = TBFieldErrorString();	
    }
    else {
	$rspec = $formfields["profile_rspec"];
    }
}
else {
    $errors["rspecfile"] = "Missing Field";
}

# Present these errors before we call out to do anything else.
if (count($errors)) {
    SPITFORM($formfields, $errors);
    return;
}

#
# Project has to exist. We need to know it for the SUEXEC call
# below. 
#
$project = Project::LookupByPid($formfields["profile_pid"]);
if (!$project) {
    $errors["profile_pid"] = "No such project";
}
# User better be a member.
if (!$project->IsMember($this_user, $isapproved) || !$isapproved) {
    $errors["profile_pid"] = "Illegal project";
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
	   htmlspecialchars($formfields["profile_description"]) .
	   "</value>");
    fwrite($fp, "</attribute>\n");
    fwrite($fp, "<attribute name='rspec'>");
    fwrite($fp, "  <value>" . htmlspecialchars($rspec) . "</value>");
    fwrite($fp, "</attribute>\n");
    fwrite($fp, "<attribute name='profile_listed'><value>");
    if (isset($formfields["profile_listed"]) &&
	$formfields["profile_listed"] == "checked") {
	fwrite($fp, "1");
    }
    else {
	fwrite($fp, "0");
    }
    fwrite($fp, "</value></attribute>\n");
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
$optarg = ($action == "edit" ? "-u" : "");
$retval = SUEXEC($this_user->uid(), $project->unix_gid(),
		 "webmanage_profile $optarg $xmlname",
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
#
# Need the index to pass back through.
#
$pid  = $formfields["profile_pid"];
$name = $formfields["profile_name"];
$query_result =
    DBQueryFatal("select idx from apt_profiles ".
		 "where pid='$pid' and name='$name'");
if (!$query_result || !mysql_num_rows($query_result)) {
    header("Location: $APTBASE/myprofiles.php");
}
else {
    $row = mysql_fetch_array($query_result);
    $idx = $row["idx"];
    header("Location: $APTBASE/manage_profile.php?action=edit&idx=$idx".
	   "&finished=1");
}

?>
