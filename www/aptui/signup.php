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
$optargs = OptionalPageArguments("create",       PAGEARG_STRING,
				 "uid",		 PAGEARG_STRING,
				 "email",        PAGEARG_STRING,
				 "pid",          PAGEARG_STRING,
				 "verify",       PAGEARG_STRING,
				 "finished",     PAGEARG_BOOLEAN,
				 "joinproject",  PAGEARG_BOOLEAN,
				 "formfields",   PAGEARG_ARRAY);

#
# Spit the form
#
function SPITFORM($formfields, $showverify, $errors)
{
    global $TBDB_UIDLEN, $TBDB_PIDLEN, $TBDOCBASE, $WWWHOST;
    global $ACCOUNTWARNING, $EMAILWARNING, $this_user, $joinproject;
    $button_label = "Create Account";

    echo "<link rel='stylesheet'
                href='formhelpers/css/bootstrap-formhelpers.min.css'>\n";

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
    $data_country = "";
    $data_state   = "";
    if (array_key_exists("country", $formfields) &&
	$formfields["country"] != "") {
	$data_country = $formfields["country"];
    }
    if (array_key_exists("state", $formfields) &&
	$formfields["state"] != "") {
	$data_state = $formfields["state"];
    }

    $formatter = function($field, $html) use ($errors) {
	$class = "form-group";
	if (array_key_exists($field, $errors)) {
	    $class .= " has-error";
	}
	echo "<div class='$class sidebyside-form'>\n";
	echo "$html\n";
	if (array_key_exists($field, $errors)) {
	    echo "<label class='control-label' for='inputError'>" .
		$errors[$field] . "</label>\n";
	}
	echo "</div>\n";
    };

    SPITHEADER(1);

    echo "<div class='row'>
           <div class='col-lg-8  col-lg-offset-2
                       col-md-10 col-md-offset-1
                       col-sm-10 col-sm-offset-1
                       col-xs-12'>\n";
    echo " <div class='panel panel-default'>
            <div class='panel-heading'>
              <h3 class='panel-title'>\n";
    if ($this_user) {
	if ($joinproject) {
	    $button_label = "Join Project";
	    echo $button_label;
	}
	else {
	    $button_label = "Create Project";
	    echo $button_label;
	}
    }
    else {
	echo "Create Account";
    }
    echo "    </h3>
             </div>
            <div class='panel-body'>\n";

    #
    # Look for non-specific error.
    #
    if (array_key_exists("error", $errors)) {
	echo "<font color=red>" . $errors["error"] . "</font>";
    } else {
        SPITABOUTACCT();
    }
    
    echo "<form id='quickvm_signup_form'
            class='form-horizontal' role='form'
            enctype='multipart/form-data'
            method='post' action='signup.php'>\n";

    echo "  <div class='row'>\n";
    if (!$this_user) {
	echo "   <div class='col-sm-6'>\n";
    }
    else {
	echo "   <div class='col-sm-12'>\n";
    }
    
    # Want to pass this along for later.
    if ($joinproject) {
	echo "<input type='hidden' name='joinproject' value=1>\n";
    }

    # Must be inside the form.
    if ($showverify) {
	SpitVerifyModal("verify_modal", $button_label);
    }
    
    #
    # It is not possible to pass through the keyfile name, but we
    # can get its contents and just pass it along in the form. We
    # do this cause if we spit the form back out with the verify email
    # modal, we will lose the ssh keyfile setting. 
    #
    if (isset($_FILES['keyfile']) &&
	$_FILES['keyfile']['name'] != "" &&
	$_FILES['keyfile']['name'] != "none") {
	
	echo "<input type='hidden' name='formfields[pubkey]' ".
	    "value='" .
	    CleanString(file_get_contents($_FILES['keyfile']['tmp_name'])) .
	    "'>";
    }
    elseif (isset($formfields["pubkey"]) && $formfields["pubkey"] != "") {
	echo "<input type='hidden' name='formfields[pubkey]' ".
	    "value='" . CleanString($formfields["pubkey"]) . "'>";
    }
    
    if (!$this_user) {
	echo "    <fieldset>
                   <legend>Personal Information</legend>\n";
	$formatter("uid",			  
		   "<input name=\"formfields[uid]\"
		       value='" . $formfields["uid"] . "'
                       class='form-control'
                       placeholder='Username' autofocus type='text'>");
	$formatter("fullname",
		   "<input name=\"formfields[fullname]\"
		       value='" . $formfields["fullname"] . "'
                       class='form-control'
                       placeholder='Full Name' type='text'>");
	$formatter("email",
		   "<input name=\"formfields[email]\"
		       value='" . $formfields["email"] . "'
                       class='form-control'
                       placeholder='Email' type='text'>");
	$formatter("affiliation",
		   "<input name=\"formfields[affiliation]\"
		       value='" . $formfields["affiliation"] . "'
                       class='form-control'
                       placeholder='Institutional Affiliation' type='text'>");
	$formatter("country",
		   "<select id='signup_countries' name=\"formfields[country]\"
                       class='form-control bfh-countries'
                       data-country='$data_country'
                       data-blank='false' data-ask='true'>
                    </select>");
	$formatter("state",
		   "<select  id='signup_states' name=\"formfields[state]\"
                       class='form-control bfh-states'
		       data-state='$data_state'
		       data-country='signup_countries' data-ask='true'
                       placeholder='State' data-blank='false'></select>");
	$formatter("city",
		   "<input name=\"formfields[city]\"
		       value='" . $formfields["city"] . "'
                       class='form-control'
                       placeholder='City' type='text'>");
	$formatter("keyfile",
		   "<span class='help-block'>SSH Public Key file</span>".
		   "<input type=file name='keyfile'
                           placeholder='SSH Public Key File'>");
	$formatter("password1",
		   "<input name=\"formfields[password1]\"
		       value='" . $formfields["password1"] . "'
                       type='password'
                       class='form-control'
                       placeholder='Password' />");
	$formatter("password2",
		   "<input name=\"formfields[password2]\"
		       value='" . $formfields["password2"] . "'
                       type='password'
                       class='form-control'
                       placeholder='Confirm Password' />");
	echo "     </fieldset>\n";
	echo "    </div>\n";
	echo "   <div class='col-sm-6'>\n";
    }
    echo "       <fieldset>";
    if ($joinproject) {
	echo "   <legend>Project Name</legend>\n";
    }
    else {
	echo "   <legend>Project Information</legend>\n";
    }
    $formatter("pid",
	       "<input name=\"formfields[pid]\"
		       value='" . $formfields["pid"] . "'
                       class='form-control'
                       placeholder='Project Name' type='text'>");
    if (! $joinproject) {
	#
	# Creating a new project.
	#
	$formatter("proj_title",
		   "<input name=\"formfields[proj_title]\"
		       value='" . $formfields["proj_title"] . "'
                       class='form-control'
                       placeholder='Project Title (short sentence)' type='text'>");
	$formatter("proj_url",
		   "<input name=\"formfields[proj_url]\"
		       value='" . $formfields["proj_url"] . "'
                       class='form-control'
                       placeholder='Project Page URL' type='text'>");
	$formatter("proj_why",
		   "<textarea name=\"formfields[proj_why]\"
		       rows=8
                       class='form-control'
                       placeholder='Project Description (details)'
                       type='textarea'>" .
		    $formfields["proj_why"] . "</textarea>");
    }
    echo "      </fieldset>
              </div>
             </div>
            <div class='row sidebyside-form'>
               <button class='btn btn-primary btn-xs pull-left'
                   type='button' name='reset' id='reset-form'>
                      Reset Form</button>
               <button class='btn btn-primary btm-sm pull-right'
                   type='submit' name='create'>$button_label</button>
            </div>
            </form>
            </div>
           </div>
          </div>
         </div>
       \n";

    echo "<script type='text/javascript'>\n";
    if ($showverify) {
        echo "window.APT_OPTIONS.ShowVerifyModal = true;\n";
    }
    echo "</script>\n";
    echo "<script src='js/lib/require.js' data-main='js/signup'></script>";
    SPITFOOTER();
}

#
# Spit information about Apt accounts
#
function SPITABOUTACCT()  {
?>
    <div class="panel panel-info">

        <div class="panel-heading">
           <h5><a data-toggle="collapse" href="#aboutacct">Do I Need An Account? <span class="glyphicon glyphicon-chevron-right pull-right"></span></a></h5>
         </div>

         <div id="aboutacct" class="panel-collapse collapse">

           <div class="panel-body">
            <p>Maybe!</p>
           </div>
         </div>
     </div>
<?php
}

if (isset($finished) && $finished) {
    SPITHEADER(1);
    echo "Thank you! Your project application is being considered by the approval committee, and you should hear back within 72 hours.";
    SPITNULLREQUIRE();
    SPITFOOTER();
    exit(0);
}

#
# If not clicked, then put up a form.
#
if (! isset($create)) {
    $defaults = array();
    $errors   = array();

    if (isset($uid)) {
	$defaults["uid"] = CleanString($uid);
    }
    if (isset($pid)) {
	$defaults["pid"] = CleanString($pid);
    }
    if (isset($email)) {
	$defaults["email"] = CleanString($email);
    }
    
    SPITFORM($defaults, 0, $errors);
    return;
}

#
# Otherwise, must validate and redisplay if errors
#
$errors = array();

#
# These fields are required
#
if (! $this_user) {
    if (!isset($formfields["uid"]) ||
	strcmp($formfields["uid"], "") == 0) {
	$errors["uid"] = "Missing Field";
    }
    elseif (!TBvalid_uid($formfields["uid"])) {
	$errors["uid"] = TBFieldErrorString();
    }
    elseif (User::Lookup($formfields["uid"]) ||
	    posix_getpwnam($formfields["uid"])) {
	$errors["uid"] = "Already in use. Pick another";
    }
    if (!isset($formfields["fullname"]) ||
	strcmp($formfields["fullname"], "") == 0) {
	$errors["fullname"] = "Missing Field";
    }
    elseif (! TBvalid_usrname($formfields["fullname"])) {
	$errors["fullname"] = TBFieldErrorString();
    }
    # Make sure user name has at least two tokens!
    $tokens = preg_split("/[\s]+/", $formfields["fullname"],
			 -1, PREG_SPLIT_NO_EMPTY);
    if (count($tokens) < 2) {
	$errors["fullname"] = "Please provide a first and last name";
    }
    if (!isset($formfields["email"]) ||
	strcmp($formfields["email"], "") == 0) {
	$errors["email"] = "Missing Field";
    }
    elseif (! TBvalid_email($formfields["email"])) {
	$errors["email"] = TBFieldErrorString();
    }
    elseif (User::LookupByEmail($formfields["email"])) {
        #
        # Treat this error separate. Not allowed.
        #
	$errors["email"] =
	    "Already in use. Did you forget to login?";
    }
    if (!isset($formfields["affiliation"]) ||
	strcmp($formfields["affiliation"], "") == 0) {
	$errors["affiliation"] = "Missing Field";
    }
    elseif (! TBvalid_affiliation($formfields["affiliation"])) {
	$errors["affiliation"] = TBFieldErrorString();
    }
    if (!isset($formfields["country"]) ||
	strcmp($formfields["country"], "") == 0) {
	$errors["country"] = "Missing Field";
    }
    elseif (! TBvalid_country($formfields["country"])) {
	$errors["country"] = TBFieldErrorString();
    }
    if (!isset($formfields["state"]) ||
	strcmp($formfields["state"], "") == 0) {
	$errors["state"] = "Missing Field";
    }
    elseif (! TBvalid_state($formfields["state"])) {
	$errors["state"] = TBFieldErrorString();
    }
    if (!isset($formfields["city"]) ||
	strcmp($formfields["city"], "") == 0) {
	$errors["city"] = "Missing Field";
    }
    elseif (! TBvalid_city($formfields["city"])) {
	$errors["city"] = TBFieldErrorString();
    }
    if (!isset($formfields["password1"]) ||
	strcmp($formfields["password1"], "") == 0) {
	$errors["password1"] = "Missing Field";
    }
    if (!isset($formfields["password2"]) ||
	strcmp($formfields["password2"], "") == 0) {
	$errors["password2"] = "Missing Field";
    }
    elseif (strcmp($formfields["password1"], $formfields["password2"])) {
	$errors["password2"] = "Does not match password";
    }
    elseif (! CHECKPASSWORD($formfields["uid"],
			    $formfields["password1"],
			    $formfields["fullname"],
			    $formfields["email"], $checkerror)) {
	$errors["password1"] = "$checkerror";
    }
}

if (!isset($formfields["pid"]) ||
    strcmp($formfields["pid"], "") == 0) {
    $errors["pid"] = "Missing Field";
}
else {
    # Lets not allow pids that are too long, via this interface.
    if (strlen($formfields["pid"]) > $TBDB_PIDLEN) {
	$errors["pid"] =
	    "too long - $TBDB_PIDLEN chars maximum";
    }
    elseif (!TBvalid_newpid($formfields["pid"])) {
	$errors["pid"] = TBFieldErrorString();
    }
    $project = Project::LookupByPid($formfields["pid"]);
    if ($joinproject) {
	if (!$project) {
	    $errors["pid"] = "No such project. Did you spell it properly?";
	}
    }
    elseif ($project) {
	$errors["pid"] = "Already in use. Select another";
    }
}
if (!$joinproject) {
    if (!isset($formfields["proj_title"]) ||
	strcmp($formfields["proj_title"], "") == 0) {
	$errors["proj_title"] = "Missing Field";
    }
    elseif (! TBvalid_description($formfields["proj_title"])) {
	$errors["proj_title"] = TBFieldErrorString();
    }
    if (!isset($formfields["proj_url"]) ||
	strcmp($formfields["proj_url"], "") == 0 ||
	strcmp($formfields["proj_url"], $HTTPTAG) == 0) {    
	$errors["proj_url"] = "Missing Field";
    }
    elseif (! CHECKURL($formfields["proj_url"], $urlerror)) {
	$errors["proj_url"] = $urlerror;
    }
    if (!isset($formfields["proj_why"]) ||
	strcmp($formfields["proj_why"], "") == 0) {
	$errors["proj_why"] = "Missing Field";
    }
    elseif (! TBvalid_why($formfields["proj_why"])) {
	$errors["proj_why"] = TBFieldErrorString();
    }
}

# Present these errors before we call out to do anything else.
if (count($errors)) {
    SPITFORM($formfields, 0, $errors);
    return;
}

#
# Lets get the user to do the email verification now before
# we go any further. We use a session variable to store the
# key we send to the user in email.
#
if (!$this_user) {
    session_start();
    if (!isset($_SESSION["verify_key"])) {
	$_SESSION["verify_key"] = substr(GENHASH(), 0, 16);
    }
    #
    # Once the user verifies okay, we remember that in the session
    # in case there is a later error below.
    #
    if (!isset($_SESSION["verified"])) {
	if (!isset($verify) || $verify == "" ||
	    $verify != $_SESSION["verify_key"]) {
	    mail($formfields["email"],
		 "Confirm your email to create your account",
		 "Here is your user verification code. Please copy and\n".
		 "paste this code into the box on the account page.\n\n".
		 "\t" . $_SESSION["verify_key"] . "\n",
		 "From: $TBMAIL_OPS");
	
	    #
            # Respit complete form but show the verify email modal.
	    #
	    SPITFORM($formfields, 1, $errors);
	    return;
	}
	#
        # Success. Lets remember that in case we get an error below and
        # the form is redisplayed. 
	#
	$_SESSION["verified"] = 1;
    }
}

if (0) {
    TBERROR("New APT User" . print_r($formfields, TRUE), 0);
    SPITFORM($formfields, 0, $errors);
    return;
}

#
# Create the User first, then the Project/Group.
# Certain of these values must be escaped or otherwise sanitized.
#
if (!$this_user) {
    $args = array();
    $args["uid"]	   = $formfields["uid"];
    $args["name"]	   = $formfields["fullname"];
    $args["email"]         = $formfields["email"];
    $args["city"]          = $formfields["city"];
    $args["state"]         = $formfields["state"];
    $args["country"]       = $formfields["country"];
    $args["shell"]         = 'tcsh';
    $args["affiliation"]   = $formfields["affiliation"];
    $args["password"]      = $formfields["password1"];
    # Flag to the backend.
    $args["viaAPT"]	   = 1;

    #
    # Backend verifies pubkey and returns error. We first look for a 
    # file and then fall back to an inline field. See SPITFORM().
    #
    if (isset($_FILES['keyfile']) &&
	$_FILES['keyfile']['name'] != "" &&
	$_FILES['keyfile']['name'] != "none") {

	$localfile = $_FILES['keyfile']['tmp_name'];
	$args["pubkey"] = file_get_contents($localfile);
	$formfields["pubkey"] = $args["pubkey"];
    }
    elseif (isset($formfields["pubkey"]) && $formfields["pubkey"] != "") {
	$args["pubkey"] = $formfields["pubkey"];
    }

    #
    # Joining a project is a different path.
    #
    if ($joinproject) {
	if (! ($user = User::NewNewUser(0, $args, $error)) != 0) {
	    $errors["error"] = $error;
	    SPITFORM($formfields, 0, $errors);
	    return;
	}
	$group = $project->LoadDefaultGroup();
	if ($project->AddNewMember($user) < 0) {
	    TBERROR("Could not add new user to project group $pid", 1);
	}
	$group->NewMemberNotify($user);
	header("Location: instantiate.php");
	return;
    }

    # Just collect the user XML args here and pass the file to NewNewProject.
    # Underneath, newproj calls newuser with the XML file.
    #
    # Calling newuser down in Perl land makes creation of the leader account
    # and the project "atomic" from the user's point of view.  This avoids a
    # problem when the DB is locked for daily backup: in newproject, the call
    # on NewNewUser would block and then unblock and get done; meanwhile the
    # PHP thread went away so we never returned here to call NewNewProject.
    #
    if (! ($newuser_xml = User::NewNewUserXML($args, $error)) != 0) {
	$errors["error"] = $error;
	TBERROR("Error Creating new APT user XML:\n${error}\n\n" .
		print_r($args, TRUE), 0);
	SPITFORM($formfields, 0, $errors);
	return;
    }
}

#
# Now for the new Project
#
$args = array();
if (isset($newuser_xml)) {
    $args["newuser_xml"]   = $newuser_xml;
}
if ($this_user) {
    # An existing, logged-in user is starting the project.
    $args["leader"]	   = $this_user->uid();
}
$args["name"]		   = $formfields["pid"];
$args["short description"] = $formfields["proj_title"];
$args["URL"]               = $formfields["proj_url"];
$args["long description"]  = $formfields["proj_why"];
# We do not care about these anymore. Just default to something.
$args["members"]           = 1;
$args["num_pcs"]           = 1;
$args["public"]            = 1;
$args["linkedtous"]        = 1;
$args["plab"]              = 0;
$args["ron"]               = 0;
$args["funders"]           = "None";
$args["whynotpublic"]      = "APT";
# Flag to the backend.
$args["viaAPT"]		   = 1;

if (! ($project = Project::NewNewProject($args, $error))) {
    $errors["error"] = $error;
    if ($suexec_retval < 0) {
	TBERROR("Error Creating APT Project\n${error}\n\n" .
		print_r($args, TRUE), 0);
    }
    SPITFORM($formfields, 0, $errors);
    return;
}
#
# Destroy the session if we had a new user. 
#
if (!$this_user) {
    session_destroy();
}

#
# Spit out a redirect so that the history does not include a post
# in it. The back button skips over the post and to the form.
# See above for conclusion.
# 
header("Location: signup.php?finished=1");

?>
