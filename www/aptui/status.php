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
include("profile_defs.php");
include("instance_defs.php");
$page_title = "Experiment Status";
$ajax_request = 0;

#
# Get current user.
#
$this_user = CheckLogin($check_status);

#
# Verify page arguments.
#
$reqargs = OptionalPageArguments("uuid",          PAGEARG_STRING,
				 "ajax_request",  PAGEARG_BOOLEAN,
				 "ajax_method",   PAGEARG_STRING,
				 "ajax_argument", PAGEARG_STRING);
if (!isset($uuid)) {
    if ($ajax_request) {
	SPITAJAX_ERROR(1, "must provide uuid");
	exit();
    }
    SPITHEADER(1);
    echo "<div class='align-center'>
            <p class='lead text-center'>
              What experiment would you like to look at?
            </p>
          </div>\n";
    SPITFOOTER();
    return;
}

#
# See if the instance exists. If not, redirect back to the create page
#
$instance = Instance::Lookup($uuid);
if (!$instance) {
    if ($ajax_request) {
	SPITAJAX_ERROR(1, "no such instance uuid: $uuid");
	exit();
    }
    SPITHEADER(1);
    echo "<div class='align-center'>
            <p class='lead text-center'>
              Experiment does not exist. Redirecting to the front page.
            </p>
          </div>\n";
    SPITFOOTER();
    flush();
    sleep(3);
    PAGEREPLACE("instantiate.php");
    return;
}
$creator = GeniUser::Lookup("sa", $instance->creator_uuid());
if (! $creator) {
    $creator = User::LookupByUUID($instance->creator_uuid());
}
if (!$creator) {
    if ($ajax_request) {
	SPITAJAX_ERROR(1, "no such instance creator uuid");
	exit();
    }
    SPITHEADER(1);
    echo "<div class='align-center'>
            <p class='lead text-center'>
               Hmm, there seems to be a problem.
            </p>
          </div>\n";
    SPITFOOTER();
    TBERROR("No creator for instance: $uuid", 0);
    return;
}
#
# Only logged in admins can access an experiment created by someone else.
#
if (! (isset($this_user) && ISADMIN())) {
    # An experiment created by a real user, can be accessed by that user only.
    # Ditto a guest user; must be the same guest.
    if (! ((get_class($creator) == "User" &&
	    isset($this_user) && $creator->uuid() == $this_user->uuid()) ||
	   (get_class($creator) == "GeniUser" &&
	    isset($_COOKIE['quickvm_user']) &&
	    $_COOKIE['quickvm_user'] == $creator->uuid()))) {
	if ($ajax_request) {
	    SPITAJAX_ERROR(1, "You do not have permission!");
	    exit();
	}
	PAGEERROR("You do not have permission to look at this experiment!");
    }
}
$slice = GeniSlice::Lookup("sa", $instance->slice_uuid());

#
# Deal with ajax requests.
#
if (isset($ajax_request)) {
    if ($ajax_method == "status") {
	SPITAJAX_RESPONSE($instance->status());
    }
    elseif ($ajax_method == "terminate") {
	SUEXEC("nobody", "nobody", "webquickvm -k $uuid",
	       SUEXEC_ACTION_IGNORE);
	SPITAJAX_RESPONSE("");
    }
    elseif ($ajax_method == "manifest") {
	SPITAJAX_RESPONSE($instance->manifest());
    }
    elseif ($ajax_method == "ssh_authobject") {
	#
	#
	#
	SPITAJAX_RESPONSE(SSHAuthObject($creator->uid(), $ajax_argument));
    }
    elseif ($ajax_method == "request_extension") {
	if (!isset($slice)) {
	    SPITAJAX_ERROR(1, "Nothing to extend!");
	    return;
	}
        # Only extend for 24 hours. More later.
	$expires_time = strtotime($slice->expires());
	if ($expires_time > time() + (3600 * 24)) {
	    sleep(2);
	    SPITAJAX_ERROR(1, "You still have lots of time left!");
	    return;
	}
	
	$retval =
	    SUEXEC("nobody", "nobody", "webquickvm -e " . 3600 * 24 . " $uuid",
		   SUEXEC_ACTION_CONTINUE);

	if ($retval == 0) {
	    # Refresh. 
	    $slice = GeniSlice::Lookup("sa", $instance->slice_uuid());
	    $new_expires = gmdate("Y-m-d\TH:i:s\Z",
				  strtotime($slice->expires()));
	    
	    SPITAJAX_RESPONSE($new_expires);

	    TBMAIL($creator->email(),
		   "APT Extension: $uuid",
		   "A request to extend your APT experiment was made and ".
		   "granted.\n".
		   "Your reason was:\n\n". $ajax_argument . "\n\n".
		   "Your experiment will now expire at $new_expires.\n\n".
		   "You can request another extension tomorrow.\n",
		   "CC: $TBMAIL_OPS");
	}
	elseif ($retval > 0) {
	    SPITAJAX_ERROR(1, $suexec_output);
	}
	else {
	    SPITAJAX_ERROR(-1, "Internal Error. Please try again later");
	}
    }
    elseif ($ajax_method == "extend") {
	SPITAJAX_ERROR(1, "Not implemented yet!");
    }
    exit();
}
SPITHEADER(1);

$style = "style='border: none;'";
$slice_urn       = "n/a";
$slice_expires   = "n/a";
if (isset($slice)) {
    $slice_urn       = $slice->urn();
    $slice_expires   = gmdate("Y-m-d\TH:i:s\Z", strtotime($slice->expires()));
    # Simpler version for directly displaying
    $slice_expires_text   = gmdate("m-d\TH:i\Z", strtotime($slice->expires()));
}
$instance_status = $instance->status();
$creator_uid     = $creator->uid();
$creator_email   = $creator->email();
$profile         = Profile::Lookup($instance->profile_idx());
$profile_name    = $profile->name();
$color           = "";
$bgtype          = "bg-info";
$statustext      = "Please wait while we get your experiment ready";
$disabled        = "disabled";
$spin            = 1;
if ($instance_status == "failed") {
    $color = "color=red";
    $spin  = 0;
    $bgtype = "bg-danger";
    $statustext = "Something went wrong, sorry! We've been notified.";
}
elseif ($instance_status == "ready") {
    $color = "color=green";
    $spin  = 0;
    $disabled = "";
    $bgtype = "bg-success";
    $statustext = "Your experiment is ready!";
}
elseif ($instance_status == "created") {
    $spinwidth = "33";
}
elseif ($instance_status == "provisioned") {
    $spinwidth = "66";
}

echo "<div class='row'>
      <div class='col-lg-6  col-lg-offset-3
                  col-md-8  col-md-offset-2
                  col-sm-10 col-sm-offset-1
                  col-xs-12 col-xs-offset-0'>\n";
echo "<div class='panel panel-default'>\n";
echo "<div class='panel-body'>\n";
echo "<table class='table table-condensed nospaceafter' $style>\n";
echo "<tr>\n";
echo "<td id='statusmessage-container' colspan=2 $style class='$bgtype'>\n";
echo "<h4 id='statusmessage'>$statustext</h4>\n";
echo "</td>\n";
echo "</tr>\n";
if ($spin) {
    echo "<tr>\n";
    echo "<td colspan=2 $style>\n";
    echo "<div id='quickvm_spinner'>\n";
    echo " <div id='quickvm_progress'
                class='progress progress-striped active'>\n";
    echo "  <div class='progress-bar' role='progressbar'
                 id='quickvm_progress_bar'
                 style='width: ${spinwidth}%;'></div>\n";
    echo " </div>\n";
    echo "</div>\n";
    echo "</td>\n";
    echo "</tr>\n";
}
echo "<tr>\n";
echo "<td class='uk-width-1-5' $style>URN:</td>\n";
echo "<td class='uk-width-4-5' $style>$slice_urn</td>\n";
echo "</tr>\n";
echo "<tr>\n";
echo "<td class='uk-width-1-5' $style>State:</td>\n";
echo "<td class='uk-width-4-5' $style>
        <span id='quickvm_status'>
         <font $color>$instance_status</font>
        </span>\n";
echo "</td>\n";
echo "</tr>\n";
echo "<tr>\n";
echo "<td class='uk-width-1-5' $style>Profile:</td>\n";
echo "<td class='uk-width-4-5' $style>$profile_name</td>\n";
echo "</tr>\n";
echo "<tr>\n";
echo "<td class='uk-width-1-5' $style>Expires:</td>\n";
echo "<td class='uk-width-4-5' $style>
         <span id='quickvm_expires'>$slice_expires_text</span> - Time left: 
         <span id='quickvm_countdown'></span></td>\n";
echo "</tr>\n";
echo "</table>\n";
echo "<div class='pull-right'>\n";
echo "  <button class='btn btn-xs btn-success' $disabled
           id='extend_button' type=button
	   data-toggle='modal' data-target='#extend_modal'>
           Extend</button>\n";
echo "  <button class='btn btn-xs btn-danger' $disabled
           id='terminate_button' type=button
	   data-toggle='modal' data-target='#terminate_modal'>
           Terminate</button>\n";
echo "</div>\n";
echo "</div>\n";
echo "</div>\n";
echo "</div>\n";
echo "</div>\n";

#
# Add a div for the instructions if there are instructions. The client
# will actually fill in the div though, since it is markdown and that
# is more easily done on the client side for now.
#
echo "<div class='row hidden' id='instructions_panel'>
      <div class='col-lg-6  col-lg-offset-3
                  col-md-8  col-md-offset-2
                  col-sm-8  col-sm-offset-2
                  col-xs-12 col-xs-offset-0'>\n";
SpitCollapsiblePanel("instructions", "Profile Instructions",<<<BODYEND
<div id="instructions_text">
</div>
BODYEND
);

echo "</div>\n"; # cols
echo "</div>\n"; # row
#
# The topo diagram goes inside this div, when it becomes available.
#
echo "<div class='row'>
      <div class='col-lg-10  col-lg-offset-1
                  col-md-10  col-md-offset-1
                  col-sm-10  col-sm-offset-1
                  col-xs-12 col-xs-offset-0'>\n";
echo "<div class='panel panel-default invisible' id='showtopo_container'>\n";
echo "<div class='panel-body'>\n";
echo "<div id='quicktabs_div'>\n";
echo "  <ul id='quicktabs' class='nav nav-tabs'>
	  <li class='active'>
             <a href='#profile' data-toggle='tab'>Topology View</a>
          </li>
	  <li>
             <a href='#listview' data-toggle='tab'>List View</a>
          </li>
	</ul>
	<div id='quicktabs_content' class='tab-content'>
          <div class='tab-pane active' id='profile'>
	    <div id='showtopo_statuspage'></div>
            <small>Click on a node to open a shell on that node. 
                   Click and drag to move things around.</small>
	  </div>
          <div class='tab-pane' id='listview'>
	    <div id='showtopo_listview'>
              <table class='table table-striped table-hover table-condensed'
                     id='listview_table'>
                <thead>
                  <tr>
                    <th>Node</th>
                    <th>Shell (in-browser)</th>
                    <th>SSH URL <small>(if you provided your own key)</small>
                     </th>
                  </tr>
                </thead>
                <tbody>
                </tbody>
              </table>
            </div>
	  </div>
	</div>\n";
echo "</div>\n"; # quicktabs
echo "</div>\n"; # body
echo "</div>\n"; # container
echo "</div>\n"; # cols
echo "</div>\n"; # row

echo "<script type='text/javascript'>\n";
echo "  window.APT_OPTIONS.uuid = '" . $uuid . "';\n";
echo "  window.APT_OPTIONS.sliceExpires = '" . $slice_expires . "';\n";
echo "  window.APT_OPTIONS.creatorUid = '" . $creator_uid . "';\n";
echo "  window.APT_OPTIONS.creatorEmail = '" . $creator_email . "';\n";
echo "</script>\n";
echo "<script src='js/lib/require.js' data-main='js/status'></script>";

#
# A modal to tell people how to register
#
echo "<!-- This is a modal -->
      <div id='register_modal' class='modal fade'>
        <div class='modal-dialog'>
        <div class='modal-content'>
        <div class='modal-header'>
          <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>&times;</button>
          <h3>Register for an account</h3>
        </div>
        <div class='modal-body'>
          <p>If you want to design your own experiments, have more then
             one active experiment at a time, or extend the life of an
             experiment longer, you should register for a full account.
             Click on the link below to take you to the registration page.
          </p><br>
               <button class='btn btn-primary align-center'
	          id='register-account'
                  type='submit' name='register'>Register</button>
        </div>
        </div>
        </div>
      </div>\n";

#
# A modal to tell people how to extend their experiment
#
echo "<!-- This is a modal -->
      <div id='extend_modal' class='modal fade'>
        <div class='modal-dialog'>
        <div class='modal-content'>
         <div class='modal-body'>
          <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>&times;</button>
          <div class='clearfix'></div>
          <div class='row'>\n";
if ($this_user) {
    echo "   <div class='col-sm-12'>";
}
else {
    echo "   <div class='col-lg-7 col-md-7' ".
	"         style='padding-right:20px; border-right: 1px solid #ccc;'>";
}
echo "        <h4>Extend for 24 hours</h4>
                If you want to extend this experiment so that it does
                not self-terminate at the time shown, just tell us why
                and we will extend it for another 24 hours.
		Watch for an email message that says its been done. 
              <form id='extend_request_form' role='form'>
               <div class='row'>
                <div class='col-lg-12 col-md-12'>
                <textarea id='why_extend' name='why_extend'
                          class='form-control'
                          placeholder='Tell us a good story please.'
                          class='align-center-inline'
                          rows=5></textarea>
               </div></div>
               <br>
               <button class='btn btn-primary btn-sm align-center'
	               id='request-extension'
                       type='submit' name='request'>Request Extension</button>
              </form>
            </div>\n";
if (!$this_user) {
    echo "  <div class='col-lg-5 col-md-5'>
               <h4>Extend for longer</h4>
               If you want to be able to use resources for more than 24
                   hours, you will need to <a href='signup.php'>sign up</a>
                   for an account, or
                   <a data-toggle='modal' data-dismiss='modal'
                      href='#quickvm_login_modal'
                      data-target='#quickvm_login_modal'>log in</a> if you 
                      already have an acount at aptlab.net or emulab.net</a>
            </div>\n";
}
echo "      </div>
            </div>
           </div>
        </div>
      </div>\n";

#
# A modal to verify termination.
#
echo "<!-- This is a modal -->
      <div id='terminate_modal' class='modal fade'>
        <div class='modal-dialog'>
        <div class='modal-content'>
        <div class='modal-body'>
         <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>&times;</button>
         <p>Are you sure you want to terminate this experiment? 
            Click on the button below if you are really sure.</p><br>
             <button class='btn btn-primary align-center' id='terminate'
                type='submit' name='terminate'>Terminate</button>
        </div>
        </div>
        </div>
      </div>\n";

SpitWaitModal("waitwait");
SpitOopsModal("oops");

SPITFOOTER();
?>
