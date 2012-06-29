# -*- powershell -*-

# Constants
$TMCCBIN    = "C:\Cygwin\usr\local\etc\emulab\tmcc.bin"
$TMCCARGS   = "-t","30"
$CYGBINPATH = "C:\Cygwin\bin"
$LOGFILE    = "C:\Temp\setnodename.log"
$CNPATH     = "HKLM:\System\CurrentControlSet\Control\ComputerName\ComputerName"
$HNPATH     = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters"

# Log to $LOGFILE
Function log($msg) {
   $time = Get-Date -format g
   ($time + ": " + $msg) | Out-File -append $LOGFILE
}

# Update the path to include Cygwin's /bin directory (including Cygwin1.dll)
$env:path += ";$CYGBINPATH"

# XXX: This doesn't work under mini-setup
#$NameObj = Get-WmiObject Win32_ComputerSystem
#$CurName = $NameObj.Item("name")
$CurName = $env:computername

$NodeID = & $TMCCBIN $TMCCARGS nodeid
if (!$? -or $NodeID -eq "UNKNOWN" -or !$NodeID) {
   log("tmcc nodeid failed!")
   exit(1)
}

# Change the node's name to nodeid from Emulab Central, if required
if ($NodeID -ne $CurName) {
   log("Computer name change required: $CurName -> $NodeID")
# XXX: Doesn't work under mini-setup
#   if (!$NameObj.rename($NodeID)) {
#      log("Name change failed: " + $Error)
#      exit(1)
#   } else {
#      log("Node rename succeeded - reboot required")
#   }

   # Change the name via the registry
   New-ItemProperty -Path $CNPATH -Name ComputerName -PropertyType String`
                    -Value $nodeid.ToUpper() -Force
   New-ItemProperty -Path $HNPATH -Name "NV Hostname" -PropertyType String`
                    -Value $nodeid -Force

} else {
  log("Current node name is correct - no changes made")
}



exit(0)

