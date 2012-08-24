#
# Script for preparing a vanilla Windows 7 installation for Emulab
#

# First, grab script arguments - I really hate that this must come first
# in a powershell script (before any other executable lines).
param([string]$actionfile)

#
# Constants
#
$MAXREBOOTWAIT = 1800
$LOGFILE="C:\temp\basesetup.log"
$FAIL = "fail"
$SUCCESS = "success"
$REG_TYPES = @("String", "Dword")


#
# Utility functions
#

# Log to $LOGFILE
Function log($msg) {
   $time = Get-Date -format g
   ($time + ": " + $msg) | Out-File -encoding "ASCII" -append $LOGFILE
}

function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
}

#
# Action execution functions
#

# Create or set an existing registry value.  Create entire key path as required.
# XXX: Update to return powershell errors
Function addreg_func($cmdarr) {
	log("addreg called with: $cmdarr")

	# set / check args
	if (!$cmdarr -or $cmdarr.count -ne 4) {
		log("addreg called with improper argument list")
		return $FAIL
	}
	$path, $vname, $type, $value = $cmdarr
	if ($REG_TYPES -notcontains $type) {
		log("ERROR: Unknown registry value type specified: $type")
		return $FAIL
	}
	if (!(Test-Path -IsValid -Path "Registry::$path")) {
		log("Invalid registry key specified: $path")
		return $FAIL
	}
	
	# Set the value, creating the full key path if necessary
	if (!(Test-Path -Path "Registry::$path")) {
		if (!(New-Item -Path "Registry::$path" -Force)) {
			log("Couldn't create registry key path: $path")
			return $FAIL
		}
	}
	if (!(New-ItemProperty -Path "Registry::$path" -Name $vname`
	      -PropertyType $type -Value $value -Force)) {
		    log("ERROR: Could not set registry value: ")
		    return $FAIL
	    }

	return $SUCCESS
}

Function reboot_func($cmdarr) {
	log("reboot called with: $cmdarr")
	if ($cmdarr) {
		$wtime, $force = $cmdarr
		if (!(isNumeric($wtime)) -or `
		    (0 -gt $wtime) -or `
		    ($MAXREBOOTWAIT -lt $wtime))
		{
			log("ERROR: Invalid reboot wait time: $wtime")
			return $FAIL
		} 
	}

	# XXX: reboot!

	return $SUCCESS
}

Function runcmd_func($cmdarr) {
	log("runcmd called with: $cmdarr")
	return $SUCCESS
}

# Main starts here
if ($actionfile -and !(Test-Path -pathtype leaf $actionfile)) {
	log("Specified action sequence file does not exist: $actionfile")
	exit 1;
} else {
	log("Executing action sequence: $actionfile")
}

# Parse and run through the actions in the input sequence
foreach ($cmdline in (Get-Content -Path $actionfile)) {
	if (!$cmdline) {
		continue
	}
	$cmd, $argtoks = $cmdline.split()
	$cmdarr = @()
	if ($argtoks) {
		$cmdargs = [string]::join(" ", $argtoks)
		$cmdarr = [regex]::split($cmdargs, '\s*;;\s*')
	}
	$result = $FAIL
	# XXX: tried to implement a function dispatch table, but couldn't
	#      get powershell to play ball.  So we have a switch statment.
	#      May try again with OOP at some point.
	switch($cmd) {
		"addreg" {
			$result = addreg_func($cmdarr)
		}
		"runcmd" {
			$result = runcmd_func($cmdarr)
		}
		"reboot" {
			$result = reboot_func($cmdarr)
		}
		default {
			log("WARNING: Skipping unknown action: $cmd")
			$result = $SUCCESS
		}
	}
	if ($result -eq $FAIL) {
		log("ERROR: Action failed: $cmdline")
		log("Exiting!")
		exit 1
	}
}
