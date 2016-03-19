<?php
#
# Copyright (c) 2000-2016 University of Utah and the Flux Group.
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
include_once("defs.php3");

#
# Get current user, but allow for anon access.
#
$this_user = CheckLogin($check_status);
$uid       = ($this_user ? $this_user->uid() : "nobody");
$anonopt   = ($this_user ? "" : "-a");

#
# Verify page arguments.
#
$reqargs = RequiredPageArguments("logfile",  PAGEARG_LOGFILE);
$optargs = OptionalPageArguments("isajax",   PAGEARG_BOOLEAN);

if (! isset($logfile)) {
    PAGEARGERROR("Must provide either a logfile ID");
}

# Check permission in the backend.
$logfileid = $logfile->logid();

#
# Spew is broken in Chrome, so we have switched to a pure ajax
# approach (thanks Jon!). If the logfile is currently open, we
# return an HTML fragment that requests this page again, but as
# an ajax request, so that the client gets periodic updates.
#
if (!isset($isajax) && $logfile->isopen()) {
   header("Content-type: text/html; charset=utf-8");
   header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
   header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
   header("Cache-Control: no-cache, must-revalidate");
   header("Pragma: no-cache");
   header("Access-Control-Allow-Origin: *");
   echo "<html>\n";
   echo "<script src='$TBBASE/apt/js/lib/jquery-2.0.3.min.js'></script>\n";
   echo "<script src='$TBBASE/apt/js/lib/underscore-min.js'></script>\n";
   readfile("fetchlogfile.html");
   echo "</html>\n";
   return;
}

#
# A cleanup function to keep the child from becoming a zombie, since
# the script is terminated, but the children are left to roam.
#
$fp = 0;

function SPEWCLEANUP()
{
    global $fp;

    if (!$fp || !connection_aborted()) {
	exit();
    }
    pclose($fp);
    exit();
}
ignore_user_abort(1);
register_shutdown_function("SPEWCLEANUP");

if ($fp =
    popen("$TBSUEXEC_PATH $uid nobody ".
	  "spewlogfile $anonopt -w -i " . escapeshellarg($logfileid), "r")) {
    header("Content-Type: text/plain");
    header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
    header("Cache-Control: no-cache, must-revalidate");
    header("Pragma: no-cache");
    header("Access-Control-Allow-Origin: *");
    flush();

    while (!feof($fp)) {
	$string = fgets($fp, 1024);
	echo "$string";
	flush();
    }
    pclose($fp);
    $fp = 0;
}
else {
    USERERROR("Logfile $logfileid is no longer valid!", 1);
}

?>
