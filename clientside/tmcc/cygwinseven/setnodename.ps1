# -*- powershell -*-

# Constants
$TMCCBIN    = "C:\Cygwin\usr\local\etc\emulab\tmcc.bin"
$TMCCARGS   = "-s","boss.emulab.net","-t","30"
$CYGBINPATH = "C:\Cygwin\bin"
$LOGFILE    = "C:\Temp\setnodename.log"

# Log to $LOGFILE
Function log($msg) {
   $time = Get-Date -format g
   ($time + ": " + $msg) | Out-File -append $LOGFILE
}

# Update the path to include Cygwin's /bin directory (including Cygwin1.dll)
$env:path += ";$CYGBINPATH"

$NameObj = Get-WmiObject Win32_ComputerSystem
$CurName = $NameObj.Item("name")

$NodeID = & $TMCCBIN $TMCCARGS nodeid
if (!$? -or $NodeID -eq "UNKNOWN" -or !$NodeID) {
   log("tmcc nodeid failed!")
   exit(1)
}

if ($NodeID -ne $CurName) {
   log("Computer name change required: $CurName -> $NodeID")
   if (!$NameObj.rename($NodeID)) {
      log("Name change failed: " + $Error)
      exit(1)
   } else {
      log("Node rename succeeded - reboot required")
   }
} else {
  log("Current node name is correct - no changes made")
}

exit(0)

