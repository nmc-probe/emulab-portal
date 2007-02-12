<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2007 University of Utah and the Flux Group.
# All rights reserved.
#
include("defs.php3");
include_once("osinfo_defs.php");
include("osiddefs.php3");

#
# Standard Testbed Header
#
PAGEHEADER("Create a new OS Descriptor");

#
# Only known and logged in users.
#
$this_user = CheckLoginOrDie();
$uid       = $this_user->uid();
$dbid      = $this_user->dbid();
$isadmin   = ISADMIN();

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("osname",      PAGEARG_STRING,
				 "project",     PAGEARG_PROJECT,
				 "description", PAGEARG_STRING,
				 "os_path",     PAGEARG_STRING,
				 "os_version",  PAGEARG_STRING,
				 "OS",          PAGEARG_STRING,
				 "os_magic",    PAGEARG_STRING,
				 "op_mode",     PAGEARG_STRING,
				 "os_shared",   PAGEARG_STRING,
				 "os_clean",    PAGEARG_STRING,
				 "os_reboot_waittime", PAGEARG_STRING);

if (!isset($osname) ||
    strcmp($osname, "") == 0) {
  FORMERROR("Descriptor Name");
}
if (!isset($project)) {
  FORMERROR("Select Project");
}
$pid = $project->pid();

if (!isset($description) ||
    strcmp($description, "") == 0) {
  FORMERROR("Description");
}				 

if (isset($os_path) &&
    strcmp($os_path, "") == 0) {
    unset($os_path);
}
if (isset($os_version) &&
    strcmp($os_version, "") == 0) {
    unset($os_version);
}

#
# Check OS.
#
if (!isset($OS) ||
    strcmp($OS, "") == 0 ||
    strcmp($OS, "none") == 0) {
    FORMERROR("Operating System (OS)");
}
elseif (! preg_match("/^[-\w]+$/", $OS)) {
    USERERROR("Operating System (OS) - Illegal Characters", 1);
}
elseif (! array_key_exists($OS, $osid_oslist)) {
    USERERROR("Operating System (OS) - Invalid OS", 1);
}
elseif (! $osid_oslist[$OS] && !$isadmin) {
    USERERROR("Operating System (OS) - Not enough permission", 1);
}

# Check OSid.
if (! ereg("^[-_a-zA-Z0-9\.]+$", $osname)) {
    USERERROR("The Descriptor name must consist of alphanumeric characters ".
	      "and dash, dot, or underscore!", 1);
}

if (isset($os_path)) {
    if (strcmp($os_path, "") == 0) {
	unset($os_path);
    }
    else {
	if (! ereg("^[-_a-zA-Z0-9\/\.:]+$", $os_path)) {
	    USERERROR("The path contains invalid characters!", 1);
	}
    }
}

if (! isset($os_version)) {
    if (! $isadmin) {
	USERERROR("You must supply a version string!", 1);
    }
    $os_version = "";
}
else if (strcmp($os_version, "") &&
	! ereg("^[-_a-zA-Z0-9\.]+$", $os_version)) {
	USERERROR("The version string contains invalid characters!", 1);
}

#
# Database limits
#
if (strlen($osname) > $TBDB_OSID_OSNAMELEN) {
    USERERROR("The Descriptor name is too long! Please select another.", 1);
}

#
# Certain of these values must be escaped or otherwise sanitized.
# 
$description = addslashes($description);
if (isset($os_magic)) {
    $os_magic = addslashes($os_magic);
}
else {
    $os_magic = "";
}

#
# Verify permission.
#
if (!$project->AccessCheck($this_user, $TB_PROJECT_MAKEOSID)) {
    USERERROR("You do not have permission to create OS Descriptors ".
	      "in Project $pid!", 1);
}

#
# Only admin types can set the shared bit,
#
if (isset($os_shared) &&
    strcmp($os_shared, "Yep") == 0) {
    if (!$isadmin) {
	USERERROR("Only Emulab Administrators can set the shared flag!", 1);
    }
    $os_shared = 1;
}
else {
    $os_shared = 0;
}

#
# Only admin types can muck with the mustclean bit.
#
if (isset($os_clean) &&
    strcmp($os_clean, "Yep") == 0) {
    if (!$isadmin) {
	USERERROR("Only Emulab Administrators can set the clean flag!", 1);
    }
    $os_mustclean = 0;
}
else {
    $os_mustclean = 1;
}

#
# OS Features.
# 
# As a side effect of validating, form the os features set as a string
# for the insertion below. 
#
$os_features_array = array();

while (list ($feature, $userokay) = each($osid_featurelist)) {
    $foo = "os_feature_$feature";
    
    if (isset($$foo) && strcmp($$foo, "checked") == 0) {
	if (!$userokay && !$isadmin) {
	    USERERROR("Feature '$feature' requires admin mode!", 1);
	}
	else {
	    $os_features_array[] = $feature;
	}
    }
}
$os_features = join(",", $os_features_array);

# Check op_mode
if (!isset($op_mode) ||
    strcmp($op_mode, "") == 0 ||
    strcmp($op_mode, "none") == 0) {
    FORMERROR("Operational Mode (op_mode)");
}
elseif (! preg_match("/^[-\w]+$/", $op_mode)) {
    USERERROR("Operational Mode (op_mode) - Illegal Characters", 1);
}
elseif (! array_key_exists($op_mode, $osid_opmodes)) {
    USERERROR("Operational Mode (op_mode) - Invalid op_mode", 1);
}
elseif (! $osid_opmodes[$op_mode] && !$isadmin) {
    USERERROR("Operational Mode (o_mode) - Not enough permission", 1);
}

# Check nextosid. Only admin users, and only allowed if no version is given.

if (isset($nextosid)) {
    if ($nextosid == "" || $nextosid == "none") {
	unset($nextosid);
    }
    elseif (!$isadmin) {
	USERERROR("Setting nextosid requires admin mode!", 1);
    }
    elseif (!TBvalid_osid($nextosid)) {
	USERERROR("NextOsid: ". TBFieldErrorString(), 1);
    }
    elseif (! OSInfo::Lookup($nextosid)) {
	USERERROR("NextOsid: $nextosid is not a known osid!", 1);
    }
}

#
# Check the reboot_waittime. Only admin users can set this. Grab default
# if not set.
#
if (isset($os_reboot_waittime) && $os_reboot_waittime != "") {
    if (!$isadmin) {
	USERERROR("Setting reboot waittime requires admin mode!", 1);
    }
    elseif (!TBvalid_integer($os_reboot_waittime)) {
	USERERROR("Reboot Waittime: ". TBFieldErrorString(), 1);
    }
}
else {
    if (! array_key_exists($OS, $osid_reboot_waitlist)) {
	USERERROR("Operating System (OS) - No default reboot waittime", 1);
    }
    else {
	$os_reboot_waittime = $osid_reboot_waitlist[$OS];
    }
}

#
# And insert the record!
#
if (isset($os_path)) {
    $os_path = "'$os_path'";
}
else {
    $os_path = "NULL";
}

DBQueryFatal("lock tables os_info write");

#
# Of course, the OS record may not already exist in the DB.
#
if (OSInfo::LookupByName($project, $osname)) {
    DBQueryFatal("unlock tables");
    USERERROR("The OS Descriptor '$osname' already exists in Project $pid! ".
              "Please select another.", 1);
}

#
# Just concat them to form a unique imageid. 
# 
$osid = "$pid-$osname";
if (OSInfo::Lookup($osid)) {
    DBQueryFatal("unlock tables");
    TBERROR("Could not form a unique osid for $pid/$osname!", 1);
}

$query_result =
    DBQueryFatal("INSERT INTO os_info ".
		 "(osname, osid, description,OS,version,path,magic,op_mode, ".
		 " osfeatures, pid, shared, creator, creator_idx, mustclean, ".
		 " created, reboot_waittime) ".
		 "VALUES ('$osname', '$osid', '$description', '$OS', ".
		 "        '$os_version', $os_path, '$os_magic', '$op_mode', ".
		 "        '$os_features', '$pid', $os_shared, ".
	         "        '$uid', '$dbid', $os_mustclean, now(), ".
		 "        $os_reboot_waittime)");

DBQueryFatal("unlock tables");

if (isset($nextosid)) {
    DBQueryFatal("update os_info set nextosid='$nextosid' where osid='$osid'");
}

# Need the object for the rest of the script
if (! ($osinfo = OSInfo::Lookup($osid))) {
    TBERROR("Could not lookup osinfo object for $osid", 1);
}

echo "<center><h3>Done!</h3></center>\n";
PAGEREPLACE(CreateURL("showosinfo", $osinfo));

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
