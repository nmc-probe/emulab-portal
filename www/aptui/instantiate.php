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
include_once("osinfo_defs.php");
include_once("geni_defs.php");
chdir("apt");
include("quickvm_sup.php");
include("instance_defs.php");
$page_title = "QuickVM Create";
$dblink = GetDBLink("sa");

#
# Get current user but make sure coming in on SSL.
#
RedirectSecure();
$this_user = CheckLogin($check_status);

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("create",        PAGEARG_STRING,
				 "profile",       PAGEARG_STRING,
				 "stuffing",      PAGEARG_STRING,
				 "verify",        PAGEARG_STRING,
				 "project",       PAGEARG_PROJECT,
				 "formfields",    PAGEARG_ARRAY,
				 "ajax_request",  PAGEARG_BOOLEAN,
				 "ajax_method",   PAGEARG_STRING,
				 "ajax_argument", PAGEARG_STRING);

#
# Deal with ajax requests.
#
# XXX Need permission checks here. 
#
if (isset($ajax_request)) {
    if ($ajax_method == "getprofile") {
	$profile_idx = addslashes($ajax_argument);
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

$profile_default  = "OneVM";
$profile_array    = array();

$query_result =
    DBQueryFatal("select * from apt_profiles ".
		 "where public=1 " .
		 ($this_user ? "or creator_idx=" . $this_user->uid_idx() : ""));
while ($row = mysql_fetch_array($query_result)) {
    $profile_array[$row["idx"]] = $row["name"];
    if ($row["pid"] == $TBOPSPID && $row["name"] == $profile_default) {
	$profile_default = $row["idx"];
    }
    if (isset($profile)) {
        # Look for the profile by project/name and switch to index.
	if (isset($project) &&
	    $row["pid"] == $project->pid() &&
	    $row["name"] == $profile) {
	    $profile = $row["idx"];
	}
        # Look for the profile by uuid and switch to index.
	elseif ($profile == $row["uuid"]) {
	    $profile = $row["idx"];
	}
    }
}

function SPITFORM($formfields, $newuser, $errors)
{
    global $TBBASE, $TBMAIL_OPS;
    global $profile_array, $this_user;

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

    $formatter = function($field, $html) use ($errors) {
	$class = "form-group";
	if ($errors && array_key_exists($field, $errors)) {
	    $class .= " has-error";
	}
	echo "<div class='$class'>\n";
	echo "     $html\n";
	if ($errors && array_key_exists($field, $errors)) {
	    echo "<label class='control-label' for='inputError'>" .
		$errors[$field] . "</label>\n";
	}
	echo "</div>\n";
    };

    SPITHEADER(1);

    echo "<div class='row'>
          <div class='col-lg-6  col-lg-offset-3
                      col-md-6  col-md-offset-3
                      col-sm-8  col-sm-offset-2
                      col-xs-12 col-xs-offset-0'>\n";
    echo "<form id='quickvm_form' role='form'
            method='post' action='instantiate.php'>\n";
    echo "<div class='panel panel-default'>
           <div class='panel-heading'>
              <h3 class='panel-title'>
                 Create an Experiment</h3></div>
           <div class='panel-body'>\n";
    echo "   <fieldset>\n";

    #
    # Look for non-specific error.
    #
    if ($errors && array_key_exists("error", $errors)) {
	echo "<font color=red><center>" . $errors["error"] . "</center></font>";
    }
    if (!isset($this_user)) {
	$formatter("username", 
		  "<input name=\"formfields[username]\"
		          value='" . $formfields["username"] . "'
                          class='form-control'
                          placeholder='Pick a user name'
                          autofocus type='text'>");
   
	$formatter("email", 
		  "<input name=\"formfields[email]\"
                          type='text'
                          value='" . $formfields["email"] . "'
                          class='form-control'
                          placeholder='Your email address' type='text'>");

	$formatter("sshkey", 
		  "<textarea name=\"formfields[sshkey]\" 
                             placeholder='Optional: your ssh public key.'
                             class='form-control'
                             rows=4 cols=45>" . $formfields["sshkey"] .
                  "</textarea>");
    }
    echo "<div id='profile_well' class='form-group well well-md'>
            <span id='selected_profile_text' class='pull-left'>
            </span>
            <input id='selected_profile' type='hidden' 
                   name='formfields[profile]'/>
              <button id='profile' class='btn btn-primary btn-xs pull-right' 
                     type='button' name='profile_button'>
                Select a Profile
              </button>\n";
    if ($errors && array_key_exists("profile", $errors)) {
	echo "<label class='control-label' for='inputError'>" .
	    $errors["profile"] .
	    " </label>\n";
    }
    echo " </div>\n";
    echo "  <span class=''
                  id='selected_profile_description'></span>\n";
    echo "</fieldset>
           <button class='btn btn-success pull-right'
              type='submit' name='create'>Create!
           </button>
           <br> 
        </div>
        </div>
        </div>
        </div>\n";
    if (!isset($this_user)) {
	SpitVerifyModal("verify_modal", "Create");
    
	if ($newuser) {
	    if (is_string($newuser)) {
		$stuffing = $newuser;
	    }
	    else {
		$stuffing = substr(GENHASH(), 0, 16);
	    }
	    mail($formfields["email"],
		 "Confirm your email to create your Experiment",
		 "Here is your user verification code. Please copy and\n".
		 "paste this code into the box on the experiment page.\n\n".
		 "      $stuffing\n",
		 "From: $TBMAIL_OPS");
	    echo "<input type='hidden' name='stuffing' value='$stuffing' />";
	}
    }
    echo "</form>\n";

    SpitTopologyViewModal("quickvm_topomodal", $profile_array);

    echo "<script type='text/javascript'>\n";
    echo "    window.PROFILE = '" . $formfields["profile"] . "';\n";
    if ($newuser) {
	echo "window.APT_OPTIONS.isNewUser = true;\n";
    }
    echo "</script>\n";
    echo "<script src='js/lib/require.js' data-main='js/instantiate'></script>";
}

if (!isset($create)) {
    $defaults = array();
    $defaults["username"] = "";
    $defaults["email"]    = "";
    $defaults["sshkey"]   = "";
    $defaults["profile"]  = (isset($profile) ? $profile : $profile_default);
	
    # 
    # Look for current user or cookie that tells us who the user is. 
    #
    if ($this_user) {
	$defaults["username"] = $this_user->uid();
	$defaults["email"]    = $this_user->email();
    }
    elseif (isset($_COOKIE['quickvm_user'])) {
	$geniuser = GeniUser::Lookup("sa", $_COOKIE['quickvm_user']);
	if ($geniuser) {
	    #
	    # Look for existing quickvm. User not allowed to create
	    # another one.
	    #
	    $instance = Instance::LookupByCreator($geniuser->uuid());
	    if ($instance && $instance->status() != "terminating") {
		header("Location: status.php?uuid=" . $instance->uuid());
		return;
	    }
	    $defaults["username"] = $geniuser->name();
	    $defaults["email"]    = $geniuser->email();
	    $defaults["sshkey"]   = $geniuser->SSHKey();
	}
    }
    SPITFORM($defaults, false, array());
    SPITFOOTER();
    return;
}
#
# Otherwise, must validate and redisplay if errors
#
$errors = array();
$args   = array();

if (!$this_user) {
    #
    # These check do not matter for a logged in user; we ignore the values.
    #
    if (!isset($formfields["email"]) || $formfields["email"] == "") {
	$errors["email"] = "Missing Field";
    }
    elseif (! TBvalid_email($formfields["email"])) {
	$errors["email"] = TBFieldErrorString();
    }
    if (!isset($formfields["username"]) || $formfields["username"] == "") {
	$errors["username"] = "Missing Field";
    }
    elseif (! TBvalid_uid($formfields["username"])) {
	$errors["username"] = TBFieldErrorString();
    }
    elseif (User::LookupByUid($formfields["username"])) {
        # Do not allow uid overlap with real users.
	$errors["username"] = "Already in use";
    }
}
if (!isset($formfields["profile"]) || $formfields["profile"] == "") {
    $errors["profile"] = "No selection made";
}
elseif (! array_key_exists($formfields["profile"], $profile_array)) {
    $errors["profile"] = "Invalid Profile: " . $formfields["profile"];
}

if (count($errors)) {
    SPITFORM($formfields, false, $errors);
    SPITFOOTER();
    return;
}

#
# More sanity checks. 
#
if (!$this_user) {
    $geniuser = GeniUser::LookupByEmail("sa", $formfields["email"]);
    if ($geniuser) {
	if ($geniuser->name() != $formfields["username"]) {    
	    $errors["email"] = "Already in use by another user";
	    unset($geniuser);
	}
    }
}
#
# SSH keys are now optional for guest users; they just have to
# use the web based ssh windo.
#
if (isset($formfields["sshkey"]) && $formfields["sshkey"] != "") {
    $args["sshkey"] = $formfields["sshkey"];
}

if (count($errors)) {
    SPITFORM($formfields, false, $errors);
    SPITFOOTER();
    return;
}
# Silently ignore the form for a logged in user. 
$args["username"] = ($this_user ? $this_user->uid() : $formfields["username"]);
$args["email"]    = ($this_user ? $this_user->email() : $formfields["email"]);
$args["profile"]  = $formfields["profile"];

#
# See if user exists and is verified. We send email with a code, which
# they have to paste back into a box we add to the form. See above.
#
# We also get here if the user exists, but the browser did not have
# the tokens, as will happen if switching to another browser. We
# force the user to repeat the verification with the same code we
# have stored in the DB.
#
if (!$this_user &&
    (!$geniuser || !isset($_COOKIE['quickvm_authkey']) ||
     $_COOKIE['quickvm_authkey'] != $geniuser->auth_token())) {
    if (isset($stuffing) && $stuffing != "") {
	if (! (isset($verify) && $verify == $stuffing)) {
	    SPITFORM($formfields, $stuffing, $errors);
	    SPITFOOTER();
	    return;
	}
	#
	# If this is an existing user and they give us the right code,
	# we can check again for an existing VM and redirect to the
	# status page, like we do above.
	#
	if ($geniuser) {
	    $instance = Instance::LookupByCreator($geniuser->uuid());
	    if ($instance && $instance->status() != "terminating") {
		header("Location: status.php?uuid=" . $instance->uuid());
		return;
	    }
	}
	# Pass to backend to save in user object.
	$args["auth_token"] = $stuffing;
    }
    else {
	# Existing user, use existing auth token.
	# New user, we create a new one.
	$token = ($geniuser ? $geniuser->auth_token() : true);

	SPITFORM($formfields, $token, $errors);
	SPITFOOTER();
	return;
    }
}

#
# This is so we can look up the slice after the backend creates it.
# We tell the backend what uuid to use.
#
$quickvm_uuid = NewUUID();

#
# Generate a temporary file and write in the XML goo. 
#
$xmlname = tempnam("/tmp", "quickvm");
if (! $xmlname) {
    TBERROR("Could not create temporary filename", 0);
    $errors["internal"] = "Transient error(1); please try again later.";
}
elseif (! ($fp = fopen($xmlname, "w"))) {
    TBERROR("Could not open temp file $xmlname", 0);
    $errors["internal"] = "Transient error(2); please try again later.";
}
else {
    fwrite($fp, "<quickvm>\n");
    foreach ($args as $name => $value) {
	fwrite($fp, "<attribute name=\"$name\">");
	fwrite($fp, "  <value>" . htmlspecialchars($value) . "</value>");
	fwrite($fp, "</attribute>\n");
    }
    fwrite($fp, "</quickvm>\n");
    fclose($fp);
    chmod($xmlname, 0666);
}
if (count($errors)) {
    SPITFORM($formfields, false, $errors);
    SPITFOOTER();
    return;
}

#
# Invoke the backend. This will create the user and the slice record
# in the SA database, and then fork off in the background. If the
# first part works, we can return to the user and use some nifty ajax
# and javascript to watch for progress. We use a cookie that holds
# the slice uuid so that the JS code can ask about it.
#
# This option is used to tell the backend that it is okay to look
# in the emulab users table.
#
$opt = ($this_user ? "-l" : "");

$retval = SUEXEC("nobody", "nobody",
		 "webquickvm $opt -u $quickvm_uuid $xmlname",
		 SUEXEC_ACTION_CONTINUE);

if ($retval != 0) {
    if ($retval < 0) {
	$errors["error"] = "Transient error(3); please try again later.";
    }
    else {
	if (count($suexec_output_array)) {
	    $line = $suexec_output_array[$i];
	    $errors["error"] = $line;
	}
	else {
	    $errors["error"] = "Transient error(4); please try again later.";
	}
    }
    SPITFORM($formfields, false, $errors);
    SPITFOOTER();
    return;
}
unlink($xmlname);

$instance = Instance::Lookup($quickvm_uuid);
if (!$instance) {
    $errors["error"] = "Transient error(5); please try again later.";
    SPITFORM($formfields, false, $errors);
    SPITFOOTER();
    return;
}
if ($this_user) {
    $creator = $this_user;
}
else {
    $creator = GeniUser::Lookup("sa", $instance->creator_uuid());
}
if (! $creator) {
    $errors["error"] = "Transient error(6); please try again later.";
    SPITFORM($formfields, false, $errors);
    SPITFOOTER();
    return;
}
#
# Remember the user and auth key so that we can verify.
#
# The cookie handling is a pain since we run this under the aptlab
# virtual host, but the config uses a different domain, and so the
# cookies do not work. So, we have to look at our SERVER_NAME and
# set the cookie appropriately. 
#
if (!$this_user) {
    $cookiedomain = $TBAUTHDOMAIN;

    setcookie("quickvm_user",
	      $creator->uuid(), time() + (24 * 3600 * 30),
	      "/", $cookiedomain, 0);
    setcookie("quickvm_authkey",
	      $creator->auth_token(), time() + (24 * 3600 * 30),
	      "/", $cookiedomain, 0);
}
header("Location: status.php?uuid=" . $instance->uuid());
?>
