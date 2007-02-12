<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2007 University of Utah and the Flux Group.
# All rights reserved.
#
include("defs.php3");
include_once("node_defs.php");

#
# Standard Testbed Header
#
PAGEHEADER("Node Control Form");

#
# Only known and logged in users can do this.
#
$this_user = CheckLoginOrDie();
$uid       = $this_user->uid();
$isadmin   = ISADMIN();

#
# Verify page arguments.
#
$reqargs = RequiredPageArguments("node", PAGEARG_NODE);

# Need these below.
$node_id = $node->node_id();

#
# Admin users can control any node, but normal users can only control
# nodes in their own experiments.
#
if (!$isadmin &&
    !$node->AccessCheck($this_user, $TB_NODEACCESS_MODIFYINFO)) {
    USERERROR("You do not have permission to modify node $node_id!", 1);
}

$node_id            = $node->node_id(); 
$type               = $node->type();
$def_boot_osid      = $node->def_boot_osid();
$def_boot_cmd_line  = $node->def_boot_cmd_line();
$next_boot_osid     = $node->next_boot_osid();
$next_boot_cmd_line = $node->next_boot_cmd_line();
$temp_boot_osid     = $node->temp_boot_osid();
$rpms               = $node->rpms();
$tarballs           = $node->tarballs();
$startupcmd         = $node->startupcmd();
$vname              = null;

# Need the reservation info.
if (($resrow = $node->ReservedTableEntry())) {
    $vname = $resrow["vname"];
}

#
# Get the OSID list. These are either OSIDs that are currently loaded on
# the node as indicated by the partitions table, or OSIDs with non-null
# paths (which means they are OSKit kernels). The list is pruned using the
# pid of the user when not an admin type, of course.
#
if ($isadmin) {
    $osid_result =
	DBQueryFatal("select o.osname, o.pid, o.osid as oosid, " .
		     "p.osid as posid from os_info as o ".
		     "left join partitions as p on o.osid=p.osid ".
		     "where p.node_id='$node_id' or ".
		     "(o.path!='' and o.path is not NULL) ".
		     "order by o.osid");
}
else {
    $uid_idx = $this_user->uid_idx();
    
    $osid_result =
	DBQueryFatal("select distinct o.osname, o.pid, o.osid as oosid," .
		     "p.osid as posid from os_info as o ".
		     "left join group_membership as m on m.pid=o.pid ".
		     "left join partitions as p on o.osid=p.osid ".
		     "where p.node_id='$node_id' or ".
		     "  ((m.uid_idx='$uid_idx' or o.shared=1) and ".
		     "   (o.path!='' and o.path is not NULL)) ".
		     "order by o.pid,o.osid");
}

echo "<table border=2 cellpadding=0 cellspacing=2
       align='center'>\n";

#
# Generate the form.
#
$url = CreateURL("nodecontrol", $node);

echo "<form action='$url' method=\"post\">\n";
echo "<tr>
          <td>Node ID:</td>
          <td class=\"left\">$node_id</td>
      </tr>\n";

if ($vname) {
    echo "<tr>
              <td>Virtual Name:</td>
              <td class=left>$vname</td>
          </tr>\n";
}

echo "<tr>
          <td>Node Type:</td>
          <td class=\"left\">$type</td>
      </tr>\n";

#
# OSID, as a menu of those allowed.
#
echo "<tr>
          <td>*Def Boot OS:</td>";
echo "    <td><select name=def_boot_osid>\n";
if ($def_boot_osid &&
    ($osinfo = OSinfo::Lookup($def_boot_osid))) {
    $osname = $osinfo->osname();
    echo "<option selected value='$def_boot_osid'>$osname </option>\n";
}
               while ($row = mysql_fetch_array($osid_result)) {
                  $osname = $row["osname"];
                  $oosid  = $row["oosid"];
		  $posid  = $row["posid"];
		  $pid    = $row["pid"];

		  # Use the osid that came from the partitions table, if there
		  # was one - otherwise, go with the os_info table
		  if ($posid) {
		  	$osid = $posid;
		  } else {
		  	$osid = $oosid;
		  }

		  if ($def_boot_osid == $osid) {
		      continue;
		  }
                  echo "<option value=$osid>$pid - $osname</option>\n";
               }
if ($isadmin) {
    echo "<option value=\"\">No OS</option>\n";
}
echo "       </select>";
echo "    </td>
      </tr>\n";

echo "<tr>
          <td>Def Boot Command Line:</td>
          <td class=\"left\">
              <input type=\"text\" name=\"def_boot_cmd_line\" size=\"40\"
                     value=\"$def_boot_cmd_line\"></td>
      </tr>\n";

if ($isadmin) {
    mysql_data_seek($osid_result, 0);

    echo "<tr>
              <td>Next Boot OS:</td>";
    echo "    <td><select name=\"next_boot_osid\">\n";
    echo "                <option value=\"\">No OS</option>\n";
    
    while ($row = mysql_fetch_array($osid_result)) {
	$osname = $row["osname"];
	$oosid = $row["oosid"];
	$posid = $row["posid"];

        # Use the osid that came from the partitions table, if there
	# was one - otherwise, go with the os_info table
	if ($posid) {
	    $osid = $posid;
	}
	else {
	    $osid = $oosid;
	}

	echo "<option ";
	if ($next_boot_osid == $osid) {
	    echo "selected ";
	}
	echo "value=\"$osid\">$pid - $osname</option>\n";
    }
    echo "       </select>";
    echo "    </td>
           </tr>\n";

    echo "<tr>
              <td>Next Boot Command Line:</td>
              <td class=\"left\">
                  <input type=\"text\" name=\"next_boot_cmd_line\" size=\"40\"
                         value=\"$next_boot_cmd_line\"></td>
          </tr>\n";

    mysql_data_seek($osid_result, 0);

    echo "<tr>
              <td>Temp Boot OS:</td>";
    echo "    <td><select name=\"temp_boot_osid\">\n";
    echo "                <option value=\"\">No OS</option>\n";
    
    while ($row = mysql_fetch_array($osid_result)) {
	$osname = $row["osname"];
	$oosid = $row["oosid"];
	$posid = $row["posid"];

        # Use the osid that came from the partitions table, if there
	# was one - otherwise, go with the os_info table
	if ($posid) {
	    $osid = $posid;
	}
	else {
	    $osid = $oosid;
	}

	echo "<option ";
	if ($temp_boot_osid == $osid) {
	    echo "selected ";
	}
	echo "value=\"$osid\">$pid - $osname</option>\n";
    }
    echo "       </select>";
    echo "    </td>
           </tr>\n";
}

echo "<tr>
          <td>Startup Command[<b>1</b>]:</td>
          <td class=\"left\">
              <input type=\"text\" name=\"startupcmd\" size=\"60\"
                     maxlength=\"256\" value='$startupcmd'></td>
      </tr>\n";


echo "<tr>
          <td>RPMs[<b>2</b>]:</td>
          <td class=\"left\">
              <input type=\"text\" name=\"rpms\" size=\"60\"
                     maxlength=\"1024\" value=\"$rpms\"></td>
      </tr>\n";

echo "<tr>
          <td>Tarballs[<b>3</b>]:</td>
          <td class=\"left\">
              <input type=\"text\" name=\"tarballs\" size=\"60\"
                     maxlength=\"1024\" value=\"$tarballs\"></td>
      </tr>\n";

echo "<tr>
          <td colspan=2 align=center>
              <b><input type=\"submit\" value=\"Submit\"></b>
          </td>
     </tr>
     </form>
     </table>\n";

echo "<p><blockquote><blockquote>
      <ol>
        <li> Node startup command must be a pathname. You may also include
                optional arguments.
        <li> RPMs must be a colon separated list of pathnames.
        <li> Tarballs must be a colon separated list of directory path
                and tarfile path (/usr/site:/foo/fee.tar.gz). The
                directory is where the tarfile should be unpacked.
      </ol>
      </blockquote></blockquote>\n";

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
