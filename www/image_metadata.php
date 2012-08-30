<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2003-2012 University of Utah and the Flux Group.
# All rights reserved.
#
include("defs.php3");
include_once("imageid_defs.php");

function SPITERROR($code, $msg)
{
    header("HTTP/1.0 $code $msg");
    exit();
}

#
# Verify page arguments.
#
$reqargs = RequiredPageArguments("uuid", PAGEARG_STRING);

$image = Image::LookupByUUID($uuid);
if (! isset($image)) {
    SPITERROR(404, "Could not find $uuid!");
}
if (! $image->isglobal()) {
    SPITERROR(403, "No permission to access image");
}

$fp = popen("$TBSUEXEC_PATH nobody nobody webdumpdescriptor ".
	    "-e -i " . $image->imageid(), "r");
if (! $fp) {
    SPITERROR(404, "Could not get metadata for $uuid!");
}

header("Content-Type: text/plain; charset=us-ascii");
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Cache-Control: no-cache, must-revalidate");
header("Pragma: no-cache");
flush();

while (!feof($fp)) {
    $string = fgets($fp, 1024);
    echo "$string";
    flush();
}
pclose($fp);
$fp = 0;

?>
