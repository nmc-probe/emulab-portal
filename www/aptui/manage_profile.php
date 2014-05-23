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
include_once("webtask.php");
chdir("apt");
include("quickvm_sup.php");
include("profile_defs.php");
include("instance_defs.php");
# Must be after quickvm_sup.php since it changes the auth domain.
include_once("../session.php");
$page_title = "Manage Profile";
$notifyupdate = 0;
$notifyclone = 0;

#
# Get current user.
#
RedirectSecure();
$this_user = CheckLogin($check_status);

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("create",      PAGEARG_STRING,
				 "action",      PAGEARG_STRING,
				 "idx",         PAGEARG_INTEGER,
				 "uuid",        PAGEARG_STRING,
				 "snapuuid",    PAGEARG_STRING,
				 "finished",    PAGEARG_BOOLEAN,
				 "formfields",  PAGEARG_ARRAY);

#
# The user must be logged in.
#
if (!$this_user) {
    RedirectLoginPage();
    exit();
}
$this_idx = $this_user->uid_idx();

#
# Spit the form
#
function SPITFORM($formfields, $errors)
{
    global $this_user, $projlist, $action;
    global $notifyupdate, $notifyclone, $snapuuid;
    $editing = 0;

    if ($action == "edit") {
	$button_label = "Modify";
	$title        = "Modify Profile";
	$editing      = 1;
	$uuid         = $formfields["profile_uuid"];
    }
    else  {
	$button_label = "Create";
	$title        = "Create Profile";
    }

    SPITHEADER(1);

    # Place to hang the toplevel template.
    echo "<div id='manage-body'></div>\n";

    # I think this will take care of XSS prevention?
    echo "<script type='text/plain' id='form-json'>\n";
    echo htmlentities(json_encode($formfields)) . "\n";
    echo "</script>\n";
    echo "<script type='text/plain' id='error-json'>\n";
    echo htmlentities(json_encode($errors));
    echo "</script>\n";

    # Pass project list through. Need to convert to list without groups.
    # When editing, pass through a single value. The template treats a
    # a single value as a read-only field.
    $plist = array();
    if ($editing) {
	$plist[] = $formfields["profile_pid"];
    }
    else {
	while (list($project) = each($projlist)) {
	    $plist[] = $project;
	}
    }
    echo "<script type='text/plain' id='projects-json'>\n";
    echo htmlentities(json_encode($plist));
    echo "</script>\n";
    
    echo "<link rel='stylesheet'
            href='css/jquery-ui-1.10.4.custom.min.css'>\n";
    echo "<link rel='stylesheet'
            href='css/jquery.appendGrid-1.3.1.min.css'>\n";
    # For progress bubbles in the imaging modal.
    echo "<link rel='stylesheet' href='css/progress.css'>\n";

    echo "<script type='text/javascript'>\n";
    echo "    window.EDITING  = " . ($editing ? 1 : 0) . ";\n";
    echo "    window.UUID     = " . (isset($uuid) ? "'$uuid'" : "null") . ";\n";
    echo "    window.UPDATED  = $notifyupdate;\n";
    echo "    window.SNAPPING = $notifyclone;\n";
    echo "    window.AJAXURL  = 'server-ajax.php';\n";
    echo "    window.ACTION   = '$action';\n";
    echo "    window.TITLE    = '$title';\n";
    echo "    window.BUTTONLABEL = '$button_label';\n";
    if (isset($snapuuid)) {
	echo "    window.SNAPUUID = '$snapuuid';\n";
    }
    echo "</script>\n";
    echo "<script src='js/lib/jquery-2.0.3.min.js'></script>\n";
    echo "<script src='js/lib/bootstrap.js'></script>\n";
    echo "<script src='js/lib/require.js' data-main='js/manage_profile'>
          </script>";
    
    SPITFOOTER();
}

#
# See what projects the user can do this in.
#
$projlist = $this_user->ProjectAccessList($TB_PROJECT_CREATEEXPT);

# We use a session.
session_start();

if (! isset($create)) {
    $errors   = array();
    $defaults = array();

    # Default action is create.
    if (! isset($action) || $action == "") {
	$action = "create";
    }
    
    if (! (isset($projlist) && count($projlist))) {
	$errors["error"] =
	    "You do not appear to be a member of any projects in which ".
	    "you have permission to create new profiles";
    }
    if ($action == "edit" || $action == "delete" || $action == "clone") {
	if ($action == "clone") {
	    if (! (isset($snapuuid) && IsValidUUID($snapuuid))) {
		$errors["error"] = "No experiment specified for clone!";
	    }
	    $instance = Instance::Lookup($snapuuid);
	    if (!$instance) {
		SPITUSERERROR("No such instance to clone!");
	    }
	    else if ($this_idx != $instance->creator_idx() && !ISADMIN()) {
		SPITUSERERROR("Not enough permission!");
	    }
	    $profile = Profile::Lookup($instance->profile_idx());
	    if (!$profile) {
		SPITUSERERROR("Cannot load profile for instance!");
	    }
	    $defaults["profile_rspec"] = $profile->rspec();
	    $defaults["profile_who"]   = "shared";
            # Default the project if in only one project.
	    if (count($projlist) == 1) {
		list($project) = each($projlist);
		reset($projlist);
		$defaults["profile_pid"] = $project;
	    }
	}
	else {
	    if (! (isset($idx) || isset($uuid))) {
		$errors["error"] = "No profile specified for edit/delete!";
	    }
	    else {
		# This can also be a uuid.
		if (isset($idx)) {
		    $profile = Profile::Lookup($idx);
		}
		elseif (isset($uuid)) {
		    $profile = Profile::Lookup($uuid);
		}
		if (!$profile) {
		    SPITUSERERROR("No such profile!");
		}
		else if ($profile->locked()) {
		    SPITUSERERROR("Profile is currently locked!");
		}
		else if ($this_idx != $profile->creator_idx() && !ISADMIN()) {
		    SPITUSERERROR("Not enough permission!");
		}
		else if ($action == "delete") {
		    $profile->Delete();
		    session_unset();
		    session_destroy();
		    header("Location: $APTBASE/myprofiles.php");
		    return;
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

		    # Warm fuzzy message.
		    if (isset($_SESSION["notifyupdate"])) {
			$notifyupdate = 1;
			unset($_SESSION["notifyupdate"]);
		    }

		    #
		    # See if we have a task running in the background
		    # for this profile. At the moment it can only be a
		    # clone task. If there is one, we have to tell
		    # the js code to show the status of the clone.
		    #
		    $webtask = WebTask::LookupByObject($profile->uuid());
		    if ($webtask && ! $webtask->exited()) {
			$notifyclone = 1;
		    }
		}
	    }
	}
    }
    else {
	# Default the project if in only one project.
	if (count($projlist) == 1) {
	    list($project) = each($projlist);
	    reset($projlist);
	    $defaults["profile_pid"] = $project;
	}
	$defaults["profile_who"]   = "shared";
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
if (!ISADMIN() &&
    (!$project->IsMember($this_user, $isapproved) || !$isapproved)) {
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

#
# Sanity check the snapuuid argument. 
#
if (isset($action) && $action == "clone") {
    if (!isset($snapuuid) || $snapuuid == "" || !IsValidUUID($snapuuid)) {
	$errors["error"] = "Invalid experiment specified for clone!";
    }
    $instance = Instance::Lookup($snapuuid);
    if (!$instance) {
	$errors["error"] = "No such experiment to clone!";
    }
    else if ($this_idx != $instance->creator_idx() && !ISADMIN()) {
	$errors["error"] = "Not enough permission!";
    }
    else {
	$profile = Profile::Lookup($instance->profile_idx());
	if (!$profile) {
	    $errors["error"] = "Cannot load profile for instance!";
	}
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
if (isset($snapuuid)) {
    $optarg .= "-s " . escapeshellarg($snapuuid);

    # We want to pass a webtask id along. 
    $webtask_id = md5(uniqid(rand(),1));
    $optarg .= " -t " . $webtask_id;
}

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
		$errors[(string)$error['name']] = (string)$error;
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
$profile = Profile::LookupByName($project, $formfields["profile_name"]);
if ($profile) {
    $uuid = $profile->uuid();
}
else {
    header("Location: $APTBASE/myprofiles.php");
}
if ($action == "edit") {
    $_SESSION["notifyupdate"] = 1;
}
header("Location: $APTBASE/manage_profile.php?action=edit&uuid=$uuid");

?>
