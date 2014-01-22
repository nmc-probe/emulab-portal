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
$APTHOST	= "$WWWHOST";
$APTBASE	= "$TBBASE/apt";

#
# Global flag to disable accounts. We do this on some pages which
# should not display login/account info.
#
$disable_accounts = 0;

#
# So, we could be coming in on the alternate APT address (virtual server)
# which causes cookie problems. I need to look into avoiding this problem
# but for now, just change the global value of the TBAUTHDOMAIN when we do.
# The downside is that users will have to log in twice if they switch back
# and forth.
#
if ($TBMAINSITE && $_SERVER["SERVER_NAME"] == "www.aptlab.net") {
    $TBAUTHDOMAIN = ".aptlab.net";
    $APTHOST      = "www.aptlab.net";
    $APTBASE      = "https://www.aptlab.net";
}

function SPITHEADER($thinheader = 0)
{
    global $TBMAINSITE;
    global $login_user, $login_status;
    global $disable_accounts;
    
    $height = ($thinheader ? 150 : 250);

    #
    # Figure out who is logged in, if anyone.
    #
    if (($login_user = CheckLogin($status)) != null) {
	$login_status = $status;
	$login_uid    = $login_user->uid();
    }

    echo "<html>
      <head>
        <title>AptLab</title>
        <link rel='stylesheet' href='bootstrap/css/bootstrap.css'>
        <link rel='stylesheet' href='quickvm.css'>
	<script src='js/lib/require.js' data-main='js/main'></script>
        <script src='https://www.emulab.net/emulab_sup.js'></script>
      </head>
    <body style='display: none'>\n";
    
    if ($TBMAINSITE && file_exists("../google-analytics.php")) {
	readfile("../google-analytics.php");
    }
    
    echo "
    <!-- Container for body, needed for sticky footer -->
    <div id='wrap'>
      <div style='background-color: #ff6600'>";
    if (!$disable_accounts) {
	if ($login_user) {
	    echo "<div id='loginbutton'>
                      $login_uid logged in<br>
                  </div>\n";
	}
	elseif (!NOLOGINS()) {
	    echo "<div id='loginbutton'>
                   <button class='btn btn-primary'
                           id='login_button' type=button
	                   data-toggle='modal' data-target='#quickvm_login_modal'>
                        Login</button>
                 </div>\n";
	}
    }
    echo "<img class='align-center' style='width: ${height}px'
               src='aptlogo.png'/>
      </div>
     <!-- Page content -->
     <div class='container'>\n";
    SpitLoginModal("quickvm_login_modal");
}

function SPITFOOTER()
{
    echo "</div>
      </div>\n";
    echo "
      <!--- Footer -->
      <div>
       <div id='footer'>
        <div class='pull-left'>Powered by
             <img src='emulab-whiteout.png' id='elabpower'></div>
        <div class='pull-right'>&copy; 2013 The University of Utah</div>
       </div>
      </div>
      <!-- Placed at the end of the document so the pages load faster -->
     </body></html>\n";
}

function SPITUSERERROR($msg)
{
    echo "<b>$msg</b>\n";
}

#
# Does not return; page exits.
#
function SPITAJAX_RESPONSE($value)
{
    $results = array(
	'code'  => 0,
	'value' => $value
	);
    echo json_encode($results);
}

function SPITAJAX_ERROR($code, $msg)
{
    $results = array(
	'code'  => code,
	'value' => $msg
	);
    echo json_encode($results);
}

#
# Spit out an info tooltip.
#
function SpitToolTip($info)
{
    echo "<a href='#' class='btn btn-xs' data-toggle='popover' ".
	"data-content='$info'> ".
        "<span class='glyphicon glyphicon-question-sign'></span> ".
        "</a>\n";
}

#
# Spit out the verify modal. We are not using real password authentication
# like the rest of the Emulab website. Assumed to be inside of a form
# that handles a create button.
#
function SpitVerifyModal($id, $label)
{
    echo "<!-- This is the user verify modal -->
          <div id='$id' class='modal fade'>
            <div class='modal-dialog'>
            <div class='modal-content'>
               <div class='modal-header'>
                <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>&times;</button>
                <h3>Important</h3>
               </div>
               <div class='modal-body'>
                    <p>Check your email for a verification code, and
                       enter it here:</p>
                       <div class='form-group'>
                        <input name='verify' class='form-control'
                               placeholder='Verification code'
                               autofocus type='text' />
                       </div>
                       <div class='form-group'>
                        <button class='btn btn-primary form-control'
                            type='submit' name='create'>
                            $label</button>
                       </div>
               </div>
            </div>
            </div>
         </div>\n";
}

#
# Spit out the login modal. 
#
function SpitLoginModal($id, $embedded = 0)
{
    echo "<!-- This is the login modal -->
          <div id='$id' class='modal fade'>
            <div class='modal-dialog'>
            <div class='modal-content'>
               <div class='modal-header'>
                <button type='button' class='close' data-dismiss='modal'
                   aria-hidden='true'>&times;</button>
                  Please login to your account.
               </div>
               <div class='modal-body'>\n";
    echo "     <div class='row'>
               <div class='col-lg-4 col-lg-offset-4
                           col-md-6 col-md-offset-3
                           col-sm-8 col-sm-offset-2
                           col-xs-12'>\n";
    if (!$embedded) {
	echo "   <form id='quickvm_login_form'
		       role='form'
                       method='post' action='login.php'>";
	echo "<input type=hidden name=refer value=1>\n";
	echo "<div id='quickvm_login_form_error'
			class='align-center'></div>\n";
    }
    echo "             <div class='form-group'>
                        <input name='uid' class='form-control'
                               placeholder='Email or Username'
                               autofocus type='text'>
                       </div>
                       <div class='form-group'>
                        <input name='password' class='form-control'
                               placeholder='Password'
                               type='password'>
                       </div>
                       <div class='form-group'>
                        <button class='btn btn-primary btn-sm'
                            id='quickvm_login_modal_button'
                            class='form-control'
                            type='submit' name='login'>
                            Login</button>
                       </div>\n";
    if (!$embedded) {
	echo "   </form>";
    }
    echo "     </div>
               </div>
               </div>
            </div>
            </div>
         </div>\n";
}

#
# Generate an authentication object to pass to the browser that
# is passed to the web server on boss. This is used to grant
# permission to the user to invoke ssh to a local node using their
# emulab generated (no passphrase) key. This is basically a clone
# of what GateOne does, but that code was a mess. 
#
function SSHAuthObject($uid, $nodeid)
{
    global $USERNODE;
	
    $file = "/usr/testbed/etc/sshauth.key";
    
    #
    # We need the secret that is shared with ops.
    #
    $fp = fopen($file, "r");
    if (! $fp) {
	TBERROR("Error opening $file", 0);
	return null;
    }
    $key = fread($fp, 128);
    fclose($fp);
    if (!$key) {
	TBERROR("Could not get key from $file", 0);
	return null;
    }
    $key   = chop($key);
    $stuff = GENHASH();
    $now   = time();


    $authobj = array('uid'       => $uid,
		     'stuff'     => $stuff,
		     'nodeid'    => $nodeid,
		     'timestamp' => $now,
		     'baseurl'   => "https://${USERNODE}",
		     'signature_method' => 'HMAC-SHA1',
		     'api_version' => '1.0',
		     'signature' => hash_hmac('sha1',
					      $uid . $stuff . $nodeid . $now,
					      $key),
    );
    return json_encode($authobj);
}

#
# This is a little odd; since we are using our local CM to create
# the experiment, we can just ask for the graphic directly.
#
function GetTopoMap($uid, $pid, $eid)
{
    global $TBSUEXEC_PATH;
    $xmlstuff = "";
    
    if ($fp = popen("$TBSUEXEC_PATH nobody nobody webvistopology ".
		    "-x -s $uid $pid $eid", "r")) {

	while (!feof($fp) && connection_status() == 0) {
	    $string = fgets($fp);
	    if ($string) {
		$xmlstuff .= $string;
	    }
	}
	return $xmlstuff;
    }
    else {
	return "";
    }
}

#
# Redirect request to https
#
function RedirectSecure()
{
    global $APTHOST;

    if (!isset($_SERVER["SSL_PROTOCOL"])) {
	header("Location: https://$APTHOST". $_SERVER['REQUEST_URI']);
	exit();
    }
}

?>