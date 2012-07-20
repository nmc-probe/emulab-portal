# -*- powershell -*-

# Constants
$BINDIR	    = "C:\Cygwin\usr\local\etc\emulab"
$CYGBINPATH = "C:\Cygwin\bin"
$TMCCBIN    = "tmcc.bin"
$TMCCARGS   = "-t","30"
$LOGMANBIN  = "logman"
$LDCNTRNAME = "ldavg"
$LDLOG      = "C:\Cygwin\var\run\ldavg.csv"
$LDMETRIC   = "\Processor(_Total)\% Processor Time"
$LDINTERVAL = 5
$LOGFILE    = "C:\Windows\Temp\setupnode.log"
$CNPATH     = "HKLM:\System\CurrentControlSet\Control\ComputerName\ComputerName"
$HNPATH     = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters"

# Log to $LOGFILE
Function log($msg) {
   $time = Get-Date -format g
   ($time + ": " + $msg) | Out-File -append $LOGFILE
}

# Update the path
$env:path += ";$BINDIR;$CYGBINPATH"

# XXX: This doesn't work under mini-setup
#$NameObj = Get-WmiObject Win32_ComputerSystem
#$CurName = $NameObj.Item("name")
$CurName = $env:computername

$NodeID = & $TMCCBIN $TMCCARGS nodeid
if (!$? -or $NodeID -eq "UNKNOWN" -or !$NodeID) {
   log("tmcc nodeid failed!")
   exit(1)
}

# Change the node's name to nodeid from Emulab Central
log("Setting node name to: $NodeID (was $CurName)")
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

# Create the load average performance counter
& $LOGMANBIN create counter $LDCNTRNAME -f csv -o $LDLOG --v -c $LDMETRIC`
  -si $LDINTERVAL -ow -max 1 -cnf 0

exit(0)
