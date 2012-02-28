<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2003-2012 University of Utah and the Flux Group.
# All rights reserved.
#
chdir("..");
require("defs.php3");

if (! $ISCLRHOUSE) {
    header("HTTP/1.0 404 Not Found");
    return;
}

#
# Note - this script is not meant to be called by humans! It returns no useful
# information whatsoever, and expects the client to fill in all fields
# properly.
#
$reqargs = RequiredPageArguments("cert", PAGEARG_ANYTHING);

# Silent error if unusually big.
if (strlen($cert) > 0x4000) {
    return;
}

$fname = tempnam("/tmp", "register_ca");
if (! $fname) {
    TBERROR("Could not create temporary filename", 0);
    return;
}
if (! ($fp = fopen($fname, "w"))) {
    TBERROR("Could not open temp file $fname", 0);
    return;
}
fwrite($fp, $cert);
fclose($fp);
chmod($fname, 0666);

$retval = SUEXEC("geniuser", $TBADMINGROUP, "webcacontrol -w $fname",
		 SUEXEC_ACTION_IGNORE);
unlink($fname);

if ($retval) {
    #
    # Want to return status to the caller.
    #
    header("HTTP/1.0 406 Not Acceptable");
}

?>
