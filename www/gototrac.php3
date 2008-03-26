<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2008 University of Utah and the Flux Group.
# All rights reserved.
#
include("defs.php3");

if (!$TRACSUPPORT) {
    header("Location: index.php3");
    return;
}

# No Pageheader since we spit out a redirection below.
$this_user = CheckLoginOrDie(CHECKLOGIN_USERSTATUS|
			     CHECKLOGIN_WEBONLY|CHECKLOGIN_WIKIONLY);
$uid       = $this_user->uid();

$geniproject = Project::Lookup("geni");
$approved    = 0;
if (! ($geniproject &&
       $geniproject->IsMember($this_user, $approved) && $approved)) {
    USERERROR("You do not have permission to access the Trac wiki!", 1);
}

$TRACURL        = "https://${USERNODE}/trac/protogeni";
$TRACCOOKIENAME = "trac_auth";

#
# Look for our cookie. If the browser has it, then there is nothing
# more to do; just redirect the user over to the wiki.
#
if (isset($_COOKIE[$TRACCOOKIENAME])) {
    header("Location: ${TRACURL}");
    return;
}

#
# Do the xlogin, which gives us back a hash to stick in the cookie.
#
SUEXEC($uid, "nobody", "tracxlogin $uid " . $_SERVER['REMOTE_ADDR'],
       SUEXEC_ACTION_DIE);

if (!preg_match("/^(\w*)$/", $suexec_output, $matches)) {
    TBERROR($suexec_output, 1);
}
setcookie($TRACCOOKIENAME,
	  $matches[1], 0, "/", $TBAUTHDOMAIN, $TBSECURECOOKIES);
header("Location: ${TRACURL}");

?>
