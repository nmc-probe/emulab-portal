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
	$uuid         = $formfields["profile_uuid"];
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

    $format_label = function($field, $label, $help = null) {
	echo "  <label for='$field' ".
	"         class='col-sm-2 control-label'>$label ";
	if ($help) {
	    echo "<a href='#' class='btn btn-xs'
                     data-toggle='popover' data-content='$help'>".
		    "<span class='glyphicon glyphicon-question-sign'>
                      </span></a>";
	}
	echo "  </label>\n";
    };

    $formatter = function($field, $label, $html, $help = null, $compact = 0)
		use ($errors, $format_label) {
	$class = "form-group";
	if ($errors && array_key_exists($field, $errors)) {
	    $class .= " has-error";
	}
	$size = 12;
	$margin = ($compact ? 5 : 15);
	echo "<div class='$class' style='margin-bottom: ${margin}px;'>\n";
	if ($label) {
	    $format_label($field, $label, $help);
	    $size = 10;
	}
	echo "  <div class='col-sm-${size}'>\n";
	echo "     $html\n";
	if ($errors && array_key_exists($field, $errors)) {
	    echo "<label class='control-label' for='inputError'>" .
		$errors[$field] . "</label>\n";
	}
	echo "  </div>\n";
	echo "</div>\n";
    };

    SPITHEADER(1);

    echo "<link rel='stylesheet'
            href='jquery-ui/css/smoothness/jquery-ui-1.10.4.custom.min.css'>\n";
    echo "<link rel='stylesheet'
            href='jquery.appendGrid/css/jquery.appendGrid-1.3.1.min.css'>\n";

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
    echo "      </div></div><fieldset>\n";

    # First row has both name and project, which makes the layout odd.
    echo "<div class='row'>\n";
    $format_label("profile_name", "Name",
		  ($editing ? null :
		   "alphanumeric, dash, underscore, no whitespace"));
    echo "<div class='col-sm-4'>\n";

    # In editing mode, pass through static values.
    if ($editing) {
	$formatter("profile_name", null,
		   "<p class='form-control-static'>" .
		       $formfields["profile_name"] . "</p>");
		   
	echo "<input type='hidden' name='formfields[profile_name]' ".
		"value='" . $formfields["profile_name"] . "'>\n";
    }
    else {
	$formatter("profile_name", null,
		   "<input name=\"formfields[profile_name]\"
		       id='profile_name'
		       value='" . $formfields["profile_name"] . "'
                       class='form-control'
                       placeholder='' type='text'>");
    }
    # End of first half of row
    echo "  </div>\n";
    # Second half of the row.
    $format_label("profile_pid", "Project");
    echo "<div class='col-sm-4'>\n";

    #
    # If user is a member of only one project, then just pass it
    # through, no need for the user to see it. Otherwise we have
    # to let the user choose.
    #
    if (count($projlist) == 1 || $editing) {
	if ($editing) {
	    $pid = $formfields["profile_pid"];
	}
	else {
	    list($pid) = each($projlist);
	}
	$formatter("profile_pid", null,
		   "<p class='form-control-static'>$pid</p>");
	echo "<input type='hidden' name='formfields[profile_pid]' ".
		"value='$pid'>\n";
    }
    else {
	$pid_options = "<option value=''>Please Select</option>\n";
	while (list($project) = each($projlist)) {
	    $selected = "";
	    if ($formfields["profile_pid"] == $project) {
		$selected = "selected";
	    }
	    $pid_options .= 
		"<option $selected value='$project'>$project</option>\n";
	}
	$formatter("profile_pid", null,
		   "<select name=\"formfields[profile_pid]\"
		            id='profile_pid' class='form-control'
                            placeholder='Please Select'>$pid_options</select>");
    }
    # End of first row.
    echo "  </div>
          </div>\n";
    echo "</fieldset><fieldset>\n";

    #
    # In edit mode, display current rspec in text area inside a modal.
    # See below for the modal. So, we need buttons to display the source
    # modal, the topo modal, in addition to a file chooser for a new rspec.
    #
    $invisible = ($editing ? "" : "invisible");
    
    $rspec_html =
	"<div class='row'>
           <div class='col-xs-3'>
                <input name='rspecfile' id='rspecfile' type=file
                 class='filestyle'
	         data-classButton='btn btn-primary btn-xs'
                 data-input='false'
                 data-buttonText='Choose " . ($editing ? "new" : "") . " file'>
           </div>
	   <div class='col-xs-2'>
              <button class='btn btn-primary btn-xs $invisible'
                      id='showtopo_modal_button'>
                      Show</button>
           </div>
           <div class='col-xs-2'>
              <button class='btn btn-primary btn-xs $invisible' type='button'
                      id='show_rspec_textarea_button'
                      data-toggle='collapse' data-target='#rspec_textarea'>
                      Edit</button>
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

    $formatter("profile_rspec", "Your rspec", $rspec_html);

    $formatter("profile_description", "Description",
	       "<textarea name=\"formfields[profile_description]\"
		          id='profile_description'
		          rows=3
                          class='form-control'
                          placeholder=''
                          type='textarea'>" .
	       $formfields["profile_description"] . "</textarea>",
	       "Briefly describe what this profile does");

    $formatter("profile_instructions", "Instructions",
	       "<textarea name=\"formfields[profile_instructions]\"
		          id='profile_instructions'
		          rows=3
                          class='form-control'
                          placeholder=''
                          type='textarea'></textarea>",
	       "Briefly describe how to use this profile after it starts. ".
	       "Double click to see it rendered.");

    # Hide this until the steps table is initialized from the rspec.
    echo "<div class='row hidden' id='profile_steps_div'>\n";
    $format_label("profile_steps", "Steps");
    echo "<div class='col-sm-10'>\n";
    echo "<table id='profile_steps' class='col-sm-12'></table>\n";
    echo "</div></div>\n";

    echo "<div class='row'>\n";
    echo "<div class='col-sm-10 col-sm-offset-2'>\n";
    $formatter("profile_listed", null,
	       "<div class='checkbox' >
                <label><input name=\"formfields[profile_listed]\" ".
	               $formfields["profile_listed"] .
	       "       id='profile_listed' value=checked
                       type=checkbox> ".
	       "List on the home page for anyone to view.</label></div>",
	       null, true);
    echo "  </div>\n";
    echo "</div>\n";

    echo "<div class='row'>\n";
    echo "<div class='col-sm-10 col-sm-offset-2'>\n";
    echo "Who can instantiate your profile?";
    echo "  </div>\n";
    echo "</div>\n";
    
    echo "<div class='row'>\n";
    echo "  <div class='col-sm-9 col-sm-offset-3'>\n";
    $formatter("profile_who", null,
	       "<div class='radio'>
                 <label>
                  <input type='radio' name='formfields[profile_who]' " .
   	          ($formfields["profile_who"] == 'public' ? "checked " : " ") .
                      "value='public'>
                   <em>Anyone</em> on the internet (guest users)
    	         </label>
                </div>
                <div class='radio'>
                 <label>
                  <input type='radio' name='formfields[profile_who]' ".
  	          ($formfields["profile_who"] == 'shared' ? "checked " : " ") .
                      "value='shared'>
                   Only registered users of the APT website
    	         </label>
                </div>
                <div class='radio'>
                 <label>
                  <input type='radio' name='formfields[profile_who]' ".
	          ($formfields["profile_who"] == 'private' ? "checked " : " ") .
                      "value='private'>
                   Only members of your project
    	         </label>
                </div>",
	       null, false);
    echo "  </div>\n";
    echo "</div>\n";
    
    if ($editing) {
    	$formatter("profile_url", "Shared URL",
		   "<input name=\"formfields[profile_url]\"
		       id='profile_url' readonly
		       value='" . $formfields["profile_url"] . "'
                       class='form-control'
                       placeholder='' type='text'>",
		   "Anyone with this URL can instantiate this profile",
		   false);
    }
    echo "      </fieldset>\n";

    echo "<div class='form-group'>
            <div class='col-sm-offset-2 col-sm-10'>
               <button class='btn btn-primary btn-sm pull-right'
                   id='profile_submit_button'
                   style='margin-right: 10px;'
                   type='submit' name='create'>$button_label</button>\n";
    if ($editing) {
	echo " <a class='btn btn-primary btn-sm pull-right'
                   style='margin-right: 10px;'
                   href='instantiate.php?profile=$uuid'
                   type='submit' name='create'>Instantiate</a>\n";
	echo " <a class='btn btn-danger btn-sm pull-left'
                   style='margin-right: 10px;'
                   href='manage_profile.php?action=delete&idx=$idx'
                   type='button' name='delete'>Delete</a>\n";
    }
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
    
    echo "<!-- This is the renderer modal -->
          <div id='renderer_modal' class='modal fade'>
          <div class='modal-dialog'>
            <div class='modal-content'>
               <div class='modal-header'>
                <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>
                   &times;</button>
                <h3>Markdown Renderer</h3>
               </div>
               <div class='modal-body'>
                 <!-- This rendering goes inside this div -->
                 <div class='panel panel-default'>
                    <div class='panel-body'>
                     <div id='renderer_modal_div'></div>
                    </div>
                 </div>
               </div>
            </div>
          </div>
          </div>\n";
    
    echo "<script type='text/javascript'>\n";
    echo "    window.EDITING = $editing;\n";
    echo "</script>\n";
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
    if ($action == "edit" || $action == "delete" || "snapshot") {
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
	    else if ($action == "snapshot") {
		$defaults["profile_rspec"]       = $profile->rspec();
	    }
	    else {
		$defaults["profile_uuid"]        = $profile->uuid();
		$defaults["profile_pid"]         = $profile->pid();
		$defaults["profile_description"] = $profile->description();
		$defaults["profile_name"]        = $profile->name();
		$defaults["profile_rspec"]       = $profile->rspec();
		$defaults["profile_created"]     = $profile->created();
		$defaults["profile_url"]         = $profile->url();
		$defaults["profile_listed"]      =
		    ($profile->listed() ? "checked" : "");
		$defaults["profile_who"] =
		    ($profile->shared() ? "shared" : 
		     ($profile->ispublic() ? "public" : "private"));

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
$required = array("pid", "name");

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
if (0 && isset($_FILES['rspecfile']) &&
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

#
# Convert profile_who to arguments.
#
if (!isset($formfields["profile_who"]) || $formfields["profile_who"] == "") {
    $errors["profile_who"] = "Missing value";
}
else {
    $who = $formfields["profile_who"];
    if (! ($who == "private" || $who == "shared" || $who == "public")) {
	$errors["profile_who"] = "Illegal value";
    }
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
    SPITFORM($formfields, $errors);
    return;
}
elseif (! ($fp = fopen($xmlname, "w"))) {
    TBERROR("Could not open temp file $xmlname", 0);
    $errors["error"] = "Internal error; Could not open temp file";
    SPITFORM($formfields, $errors);
    unlink($xmlname);
    return;
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
    fwrite($fp, "<attribute name='profile_shared'><value>" .
	   ($who == "shared" ? 1 : 0) . "</value></attribute>\n");
    fwrite($fp, "<attribute name='profile_public'><value>" .
	   ($who == "public" ? 1 : 0) . "</value></attribute>\n");
    fwrite($fp, "</profile>\n");
    fclose($fp);
    chmod($xmlname, 0666);
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
unlink($xmlname);
if (count($errors)) {
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
