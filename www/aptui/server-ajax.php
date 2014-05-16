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
# Redefine this so we return XML instead of html for all errors.
#
$PAGEERROR_HANDLER = function($msg, $status_code = 0) {
    if ($status_code == 0) {
	$status_code = 1;
    }
    SPITAJAX_ERROR(1, $msg);
    return;
};

#
# At this point, must always be a logged in user.
#
$this_user = CheckLogin($check_status);
if (!$this_user) {
    SPITAJAX_ERROR(2, "Your login has timed out");
    return;
}
$this_idx = $this_user->uid_idx();

#
# Verify page arguments.
#
$optargs = RequiredPageArguments("ajax_request",  PAGEARG_BOOLEAN,
				 "ajax_method",   PAGEARG_STRING,
				 "ajax_args",     PAGEARG_ARRAY);

#
# If we get more then a few, this will be annyoing.
#
if ($ajax_method == "SnapShotStatus") {
    include("manage_profile.ajax");
    Do_SnapShotStatus();
}
if ($ajax_method == "GetProfile") {
    include("myprofiles.ajax");
    Do_GetProfile();
}
else {
    SPITAJAX_ERROR(1, "Unknown request");
}
?>
