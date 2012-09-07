#
# Script for preparing a vanilla Windows 7 installation for Emulab
#

# First, grab script arguments - I really hate that this must come first
# in a powershell script (before any other executable lines).
param([string]$actionfile, [switch]$debug, [string]$logfile)

#
# Constants
#
$MAXSLEEP = 1800
$DEFLOGFILE="C:\Windows\Temp\basesetup.log"
$FAIL = "fail"
$SUCCESS = "success"
$REG_TYPES = @("String", "Dword")
$BASH = "C:\Cygwin\bin\bash"
$BASHCMD = $BASH + " -l -c "
$CMDTMP = "C:\Windows\Temp\_tmpout-basesetup"

#
# Global Variables
#
$outlog = $DEFLOGFILE

#
# Utility functions
#

# Log to $LOGFILE
Function log($msg) {
	$time = Get-Date -format g
	($time + ": " + $msg) | Out-File -encoding "ASCII" -append $outlog
}

Function debug($msg) {
	if ($debug) {
		log("DEBUG: $msg")
	}
}

Function lograw($msg) {
	$msg | Out-File -encoding "ASCII" -append $outlog
}

Function logfilecontents($fname) {
	Get-Content $fname | Out-File -encoding "ASCII" -append $outlog
}

Function isNumeric ($x) {
	$x2 = 0
	$isNum = [System.Int32]::TryParse($x, [ref]$x2)
	return $isNum
}

#
# Action execution functions
#

Function log_func($cmdarr) {
	foreach ($logline in $cmdarr) {
		log($logline)
	}

	return $SUCCESS
}

# Create or set an existing registry value.  Create entire key path as required.
# XXX: Update to return powershell errors
Function addreg_func($cmdarr) {
	debug("addreg called with: $cmdarr")

	# set / check args
	if (!$cmdarr -or $cmdarr.count -ne 4) {
		log("addreg called with improper argument list")
		return $FAIL
	}
	$path, $vname, $type, $value = $cmdarr
	$regpath = "Registry::$path"
	if ($REG_TYPES -notcontains $type) {
		log("ERROR: Unknown registry value type specified: $type")
		return $FAIL
	}
	if (!(Test-Path -IsValid -Path $regpath)) {
		log("Invalid registry key specified: '$path'")
		return $FAIL
	}
	
	# Set the value, creating the full key path if necessary
	if (!(Test-Path -Path $regpath)) {
		if (!(New-Item -Path $regpath -Force)) {
			log("Couldn't create registry key path: '$path'")
			return $FAIL
		}
	}
	if (!(New-ItemProperty -Path $regpath -Name $vname `
	      -PropertyType $type -Value $value -Force)) {
		    log("ERROR: Could not set registry value: '$vname' to '$value'")
		    return $FAIL
	    }

	return $SUCCESS
}

Function reboot_func($cmdarr) {
	debug("reboot called with: $cmdarr")

	if ($cmdarr) {
		$force = $cmdarr
	}

	# Reboot ...
	if ($force) {
		"force reboot..." | Out-Host
		#Retart-Computer -Force
	} else {
		"reboot..." | Out-Host
		#Restart-Computer
	}

	return $SUCCESS
}

Function sleep_func($cmdarr) {
	debug("sleep called with: $cmdarr")

	if ($cmdarr.count -lt 1) {
		log("ERROR: Must supply a time to sleep!")
		return $FAIL
	}

	$wtime = $cmdarr[0]
	if (!(isNumeric($wtime)) -or `
	    (0 -gt $wtime) -or `
	    ($MAXSLEEP -lt $wtime))
	{
		log("ERROR: Invalid sleep time: $wtime")
		return $FAIL
	}

	# Sleep...
	Start-Sleep -s $wtime
	
	return $SUCCESS
}

Function runcmd_func($cmdarr) {
	debug("runcmd called with: $cmdarr")

	if ($cmdarr.count -lt 1) {
		log("No command given to run.")
		return $FAIL
	}

	$cmd, $cmdargs, $expret = $cmdarr
	
	# XXX: Implement timeout?
	$procargs = @{
		FilePath = $cmd
		ArgumentList = $cmdargs
		RedirectStandardOutput = $CMDTMP
		NoNewWindow = $true
		PassThru = $true
		Wait = $true
	}
	$proc = $null
	try {
		$proc = Start-Process @procargs
	} catch {
		log("ERROR: failed to execute command: $cmd: $_")
		Remove-Item -Path $CMDTMP
		return $FAIL
	}
	
	if ($debug) {
		debug("Command output:")
		logfilecontents($CMDTMP)
	}
	
	Remove-Item -Path $CMDTMP

	# $null is a special varibale in PS - always null!
	if ($expret -ne $null -and $proc.ExitCode -ne $expret) {
		log("Command returned unexpected code: " + $proc.ExitCode)
		return $FAIL
	}

	return $SUCCESS
}

Function runcyg_func($cmdarr) {
	debug("runcyg called with: $cmdarr")

	if ($cmdarr.count -lt 1) {
		log("No command given to run.")
		return $FAIL
	}

	if (!(Test-Path $BASH)) {
		log("Bash not present - Is Cygwin installed?")
		return $FAIL
	}

	$cmdarr[0] = $BASHCMD + $cmdarr[0]
	return runcmd_func($cmdarr)	
}

Function getfile_func($cmdarr) {
	debug("getfile called with: $cmdarr")
	$retcode = $FAIL

	if ($cmdarr.count -lt 2) {
		log("URL and local file must be provided.")
		return $FAIL
	}

	$url, $filename = $cmdarr
	if (Test-Path -Path $filename) {
		log("WARNING: Overwriting existing file: $filename")
	}
	
	try {
		$webclient = New-Object System.Net.WebClient
		$webclient.DownloadFile($url,$filename)
		$retcode = $SUCCESS
	} catch {
		log("Error Trying to download file: $filename: $_")
		$retcode = $FAIL
	}

	return $retcode
}

Function mkdir_func($cmdarr) {
	debug("mkdir called with: $cmdarr")
	if ($cmdarr.count -ne 1) {
		log("Must specify directory to create and nothing else!")
		return $FAIL
	}

	$dir = $cmdarr[0]
	if (Test-Path -Path $dir) {
		if (Test-Path -PathType Leaf -Path $dir) {
			log("ERROR: Path already exists, but is not a directory!")
			return $FAIL
		} else {
			log("WARNING: Path already exists: $dir")
		}
	} elseif (!(Test-Path -IsValid -Path $dir)) {
		log("ERROR: Invalid path specified: $dir")
		return $FAIL
	} else {
		try {
			New-Item -ItemType Directory -Path $dir
		} catch {
			log("Error creating new directory: $dir: $_")
			return $FAIL
		}
	}

	return $SUCCESS
}

Function waitproc_func($cmdarr) {
	debug("waitproc called with: $cmdarr")

	if ($cmdarr.count -lt 2) {
		log("Must specify process name and timeout.")
		return $FAIL
	}

	$procname, $timeout, $excode = $cmdarr

	$proc = $null
	try {
		$proc = get-process -name $procname
	} catch {
		log("WARNING: Process not found: $procname")
	} 

	if ($proc) {
		if (!($proc.WaitForExit(1000 * $timeout))) {
			log("ERROR: timeout waiting for process: $procname")
			return $FAIL
		}

		if ($excode -and $proc.ExitCode -ne $excode) {
			log("ERROR: process exited with unexpected code: $proc.ExCode")
			return $FAIL
		}
	}
	
	return $SUCCESS

}

# Main starts here
if ($logfile) {
	if (Test-Path -IsValid -Path $logfile) {
		$outlog = $logfile
	} else {
		Write-Host "ERROR: Can't use logfile specified: $logfile"
		exit 1
	}
}

if ($actionfile -and !(Test-Path -pathtype leaf $actionfile)) {
	log("Specified action sequence file does not exist: $actionfile")
	exit 1;
} else {
	log("Executing action sequence: $actionfile")
}

# Parse and run through the actions in the input sequence
foreach ($cmdline in (Get-Content -Path $actionfile)) {
	if (!$cmdline -or ($cmdline.startswith("#"))) {
		continue
	}
	$cmd, $argtoks = $cmdline.split()
	$cmdarr = @()
	if ($argtoks) {
		$cmdargs = [string]::join(" ", $argtoks)
		#$cmdargs = [regex]::replace($cmdargs,',','`,')
		$cmdarr = [regex]::split($cmdargs, '\s*;;\s*')
	}
	$result = $FAIL
	# XXX: Maybe refactor all of this with OOP at some point.
	switch($cmd) {
		"log" {
			$result = log_func($cmdarr)
		}
		"addreg" {
			$result = addreg_func($cmdarr)
		}
		"runcmd" {
			$result = runcmd_func($cmdarr)
		}
		"runcyg" {
			$result = runcyg_func($cmdarr)
		}
		"reboot" {
			$result = reboot_func($cmdarr)
		}
		"sleep" {
			$result = sleep_func($cmdarr)
		}
		"getfile" {
			$result = getfile_func($cmdarr)
		}
		"mkdir" {
			$result = mkdir_func($cmdarr)
		}
		"waitproc" {
			$result = waitproc_func($cmdarr)
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
