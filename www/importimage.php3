<?php
#
# Copyright (c) 2013 University of Utah and the Flux Group.
# 
# {{{EMULAB-LICENSE
# 
# This file is part of the Emulab network testbed software.
# 
# This file is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
# 
# }}}
#
include("defs.php3");
include_once("imageid_defs.php");
include_once("osinfo_defs.php");
include_once("node_defs.php");
include_once("osiddefs.php3");

#
# XXX
# In this form, we make the images:imagename and the os_info:osname the same!
# Currently, TBDB_OSID_OSNAMELEN is shorter than TBDB_IMAGEID_IMAGENAMELEN
# and that causes problems since we use the same id for both tables. For
# now, test for the shorter of the two.
# 
#
# Only known and logged in users.
#
$this_user = CheckLoginOrDie();
$uid       = $this_user->uid();
$dbid      = $this_user->dbid();
$isadmin   = ISADMIN();

# This will not return if its a sajax request.
include("showlogfile_sup.php3");

#
# Verify page arguments.
#
$optargs = OptionalPageArguments("submit",       PAGEARG_STRING,
				 "canceled",     PAGEARG_BOOLEAN,
				 "confirmed",    PAGEARG_BOOLEAN,
				 "formfields",   PAGEARG_ARRAY);


#
# Options for using this page with different types of nodes.
# nodetype controls the view and trumps nodeclass.
# nodeclass determines what node types are visible from the DB.
#
    $title = "PCVM Form";
    $nodeclass = "pcvm";
    # Default to imagezip ndz files
    $filename_extension = "ndz";
    $view = array('hide_partition' => 1,
		  'hide_upload' => 1,
		  'hide_mbr' => 1,
		  'hide_concurrent' => 1,
		  'hide_footnotes' => 1,
		  'hide_wholedisk' => 1);

#
# Standard Testbed Header
#
PAGEHEADER("Import an external image");

#
# See what projects the uid can do this in.
#
$projlist = $this_user->ProjectAccessList($TB_PROJECT_MAKEIMAGEID);

if (! count($projlist)) {
    USERERROR("You do not appear to be a member of any Projects in which ".
	      "you have permission to create new Image descriptors.", 1);
}


#
# Verify that pcvms are possible
#

$types_querystring = "select distinct type from node_types ".
	    "where type='pcvm'";
$types_result = DBQueryFatal($types_querystring);


$mtypes_array = array();
mysql_data_seek($types_result, 0);
$pcvm_possible = false;
while ($row = mysql_fetch_array($types_result)) {
    $type = $row["type"];

    #
    # Look if pcvms are possible
    # 
    if ($type == "pcvm"){
	$pcvm_possible = true;
    }
}

# TODO: Something better here
if (!$pcvm_possible){
    echo "Emulab doesn't support PCVM. Talk to your admin about this<\n>";
}


#
# Spit the form out using the array of data.
#
function SPITFORM($formfields, $errors)
{
    global $projlist, $isadmin, $types_result, $osid_oslist, $osid_opmodes,
	$osid_featurelist, $nodetype, $filename_extension, $help_message;
    global $nodeclass, $node;
    global $TBDB_OSID_OSNAMELEN, $TBDB_NODEIDLEN;
    global $TBDB_OSID_VERSLEN, $TBBASE, $TBPROJ_DIR, $TBGROUP_DIR;
    global $view;
    
    #
    # Explanation of the $view argument: used to turn on and off display of
    # various parts of the form, so that it can be used for different types
    # of nodes. It's an associative array, with contents like:'hide_partition'.
    # In general, when an option is hidden, it is replaced with a hidden
    # field from $formfields
    #
    if ($help_message) {
        echo "<center><b>$help_message</b></center>\n";
    }
    
    if ($errors) {
	echo "<table class=nogrid
                     align=center border=0 cellpadding=6 cellspacing=0>
              <tr>
                 <th align=center colspan=2>
                   <font size=+1 color=red>
                      &nbsp;Oops, please fix the following errors!&nbsp;
                   </font>
                 </td>
              </tr>\n";

	while (list ($name, $message) = each ($errors)) {
            # XSS prevention.
	    $message = CleanString($message);
	    echo "<tr>
                     <td align=right>
                       <font color=red>$name:&nbsp;</font></td>
                     <td align=left>
                       <font color=red>$message</font></td>
                  </tr>\n";
	}
	echo "</table><br>\n";
    }
    # XSS prevention.
    while (list ($key, $val) = each ($formfields)) {
	$formfields[$key] = CleanString($val);
    }

    echo "<br>
          <table align=center border=1> 
          <tr>
             <td align=center colspan=2>
                 <em>(Fields marked with * are required)</em>
             </td>
          </tr>
          <form action='importimage.php3' enctype=\"multipart/form-data\"
              method=post name=idform>\n";

    #
    # Carry along the nodetype variable - have to do it here, so that's inside
    # the form
    #
    if (isset($nodetype)) {
	echo "<input type=hidden name=nodetype value='$nodetype'>";

    }
    elseif (isset($nodeclass)) {
	echo "<input type=hidden name=nodeclass value='$nodeclass'>";
    }
    if (isset($node)) {
	$id = $node->node_id();
	echo "<input type=hidden name=node_id value='$id'>";
    }

    #
    # Select Project
    #
    echo "<tr>
              <td>*Select Project:</td>
              <td><select name=\"formfields[pid]\">
                          
                      <option value=''>Please Select &nbsp</option>\n";
    
    while (list($project) = each($projlist)) {
	$selected = "";

	if ($formfields["pid"] == $project)
	    $selected = "selected";
	
	echo "        <option $selected value='$project'>$project </option>\n";
    }
    echo "       </select>";
    echo "    </td>
          </tr>\n";

    #
    # Select a group
    # 
    echo "<tr>
              <td >Group:</td>
              <td><select name=\"formfields[gid]\">
                    <option value=''>Default Group </option>\n";

    reset($projlist);
    while (list($project, $grouplist) = each($projlist)) {
	for ($i = 0; $i < count($grouplist); $i++) {
	    $group    = $grouplist[$i];

	    if (strcmp($project, $group)) {
		$selected = "";

		if (isset($formfields["gid"]) &&
		    isset($formfields["pid"]) &&
		    strcmp($formfields["pid"], $project) == 0 &&
		    strcmp($formfields["gid"], $group) == 0)
		    $selected = "selected";
		
		echo "<option $selected value=\"$group\">
                           $project/$group</option>\n";
	    }
	}
    }
    echo "     </select>
             </td>
          </tr>\n";

    #
    # Image Name
    #
    echo "<tr>
              <td>*Descriptor Name (no blanks):</td>
              <td class=left>
                  <input type=text
                         name=\"formfields[imagename]\"
                         value=\"" . $formfields["imagename"] . "\"
	                 size=$TBDB_OSID_OSNAMELEN
                         maxlength=$TBDB_OSID_OSNAMELEN>
              </td>
          </tr>\n";

    #
    # Description
    #
    echo "<tr>
              <td>*Description:<br>
                  (a short pithy sentence)</td>
              <td class=left>
                  <input type=text
                         name=\"formfields[description]\"
                         value=\"" . $formfields["description"] . "\"
	                 size=50>
              </td>
          </tr>\n";

    #
    # Version String
    #
    if (isset($view["hide_version"])) {
	spithidden($formfields, 'version');
    } else {
	echo "<tr>
		  <td>*OS Version:<br>
		      (eg: 4.3, 7.2, etc.)</td>
		  <td class=left>
		      <input type=text
			     name=\"formfields[version]\"
			     value=\"" . $formfields["version"] . "\"
			     size=$TBDB_OSID_VERSLEN
			     maxlength=$TBDB_OSID_VERSLEN>
		  </td>
	      </tr>\n";
    }

    #
    # Maxiumum concurrent loads
    #
    if (isset($view["hide_concurrent"])) {
	spithidden($formfields, 'max_concurrent');
    } else {
	echo "<tr>
		  <td>Maximum concurrent loads[<b>7</b>]:</td>
		  <td class=left>
		      <input type=text
			     name=\"formfields[max_concurrent]\"
			     value=\"" . $formfields["max_concurrent"] . "\"
			     size=4 maxlength=4>
		  </td>
	      </tr>\n";

    }


    #
    # Shared?
    #
    if (isset($view["hide_snapshot"])) {
	spithidden($formfields, 'shared');
    } else {
	echo "<tr>
		  <td>Shared?:<br>
		      (available to all subgroups)</td>
		  <td class=left>
		      <input type=checkbox
			     name=\"formfields[shared]\"
			     value=Yep";

	if (isset($formfields["shared"]) &&
	    strcmp($formfields["shared"], "Yep") == 0)
	    echo "           checked";
	    
	echo "                       > Yes
		  </td>
	      </tr>\n";
    }

    if ($isadmin) {
        #
        # Global?
        #
	echo "<tr>
  	          <td>Global?:<br>
                      (available to all projects)</td>
                  <td class=left>
                      <input type=checkbox
                             name=\"formfields[global]\"
                             value=Yep";

	if (isset($formfields["global"]) &&
	    strcmp($formfields["global"], "Yep") == 0)
	    echo "           checked";
	
	echo "                       > Yes
                  </td>
              </tr>\n";
    }
    #
    # Reboot waittime. 
    # 
    if (!isset($view["hide_footnotes"])) {
	$footnote = "[<b>8</b>]";
    } else {
	$footnote = "";
    }
    echo "<tr>
	      <td>Reboot Waittime (seconds)${footnote}:</td>
	      <td class=left>
		  <input type=text
		         name=\"formfields[reboot_waittime]\"
			 value=\"" . $formfields["reboot_waittime"] . "\"
			 size=4 maxlength=4>
   	      </td>
	  </tr>\n";

    echo "<tr>
              <td align=center colspan=2>
                  <b><input type=submit name=submit value=Submit></b>
              </td>
          </tr>\n";

    echo "</form>
          </table>\n";

    if (isset($view["hide_footnotes"])) {
	echo "<center><blockquote>
	      <b>In general, you should leave the default settings alone!</b>
              </blockquote></center>\n";
    }
    else {
	echo "<blockquote>
	      <ul>
		 <li> Only linux machines are supported for this type of import. </li>
		 <li> You will have to run the given script on a machine you want to import. The script will image and push the image to emulab </li>
		     
	      </ul>
	      </blockquote>\n";
    }
}

#
# If the given field is defined in the given set of fields, spit out a hidden
# form element for it
#
function spithidden($formfields, $field) {
    if (isset($formfields[$field])) {
	echo "<input type=hidden name=formfields[$field] value='" .
	     $formfields[$field] . "'>\n";
    }
}

#
# On first load, display a virgin form and exit.
#
if (!isset($submit)) {
    $defaults = array();
    $defaults["pid"]		 = "";
    $defaults["gid"]		 = "";
    $defaults["imagename"]	 = "";
    $defaults["description"]	 = "";
    $defaults["node_id"]	 = (isset($node) ? $node->node_id() : "");
    $defaults["max_concurrent"]	 = "";
    $defaults["shared"]		 = "No";
    $defaults["global"]		 = "No";
    $defaults["OS"]	 	 = "";
    $defaults["version"]	 = "";
    $defaults["wholedisk"]	 = "No";
    $defaults["reboot_waittime"] = "";
    $defaults["mbr_version"]     = "";

    #
    # Use the base image to seed the form.
    #
    # For users that are in one project and one subgroup, it is usually
    # the case that they should use the subgroup, and since they also tend
    # to be in the naive portion of our users, give them some help.
    # 
    if (count($projlist) == 1) {
	list($project, $grouplist) = each($projlist);

	if (count($grouplist) <= 2) {
	    $defaults["pid"] = $project;
	    if (count($grouplist) == 1 || strcmp($project, $grouplist[0]))
		$group = $grouplist[0];
	    else {
		$group = $grouplist[1];
	    }
	    $defaults["gid"] = $group;
	}
	reset($projlist);
    }
    elseif (isset($node)) {
	#
	# Use the current pid/eid of the experiment the node is in.
	#
	$experiment = $node->Reservation();
	if ($experiment) {
	    $defaults["pid"] = $experiment->pid();
	    $defaults["gid"] = $experiment->gid();
	}
    }

    #
    # Allow formfields that are already set to override defaults.
    #
    if (isset($formfields)) {
	while (list ($field, $value) = each ($formfields)) {
	    $defaults[$field] = $formfields[$field];
	}
    }

    SPITFORM($defaults, 0);
    PAGEFOOTER();
    return;
}

#
# Otherwise, must validate and redisplay if errors
#
$errors  = array();

# Be friendly about the required form field names.
if (!isset($formfields["imagename"]) ||
    strcmp($formfields["imagename"], "") == 0) {
    $errors["Descriptor Name"] = "Missing Field";
}

if (!isset($formfields["description"]) ||
    strcmp($formfields["description"], "") == 0) {
    $errors["Descriptor Name"] = "Missing Field";
}

if (!isset($formfields["version"]) ||
    strcmp($formfields["version"], "X") == 0) {
    $errors["Operating System"] = "Missing Field";
}

$project = null;
$group   = null;

#
# Project:
#
if (!isset($formfields["pid"]) ||
    strcmp($formfields["pid"], "") == 0) {
    $errors["Project"] = "Not Selected";
}
elseif (!TBvalid_pid($formfields["pid"])) {
    $errors["Project"] = "Invalid project name";
}
elseif (! ($project = Project::Lookup($formfields["pid"]))) {
    $errors["Project"] = "Invalid project name";
}

if (isset($formfields["gid"]) && $formfields["gid"] != "") {
    if ($formfields["pid"] == $formfields["gid"] && $project) {
	$group = $project->DefaultGroup();
    }
    elseif (!TBvalid_gid($formfields["gid"])) {
	$errors["Group"] = "Invalid group name";
    }
    elseif ($project &&
	    ! ($group = $project->LookupSubgroupByName($formfields["gid"]))) {
	$errors["Group"] = "Invalid group name";
    }
}
elseif ($project) {
    $group = $project->DefaultGroup();
}

# Permission check if we managed to get a proper group above.
if ($group &&
    ! $group->AccessCheck($this_user, $TB_PROJECT_MAKEIMAGEID)) {
    $errors["Project"] = "Not enough permission";
}
 
#
# Build up argument array to pass along.
#
$args = array();

# Ignore the form for this ...
if (isset($formfields["def_parentosid"]) &&
    $formfields["def_parentosid"] != "") {
    $osinfo = OSinfo::Lookup($formfields["def_parentosid"]);
    $args["def_parentosid"] = $osinfo->pid() . "," . $osinfo->osname();
}

if (isset($formfields["pid"]) && $formfields["pid"] != "") {
    $args["pid"] = $pid = $formfields["pid"];
}

if (isset($formfields["gid"]) && $formfields["gid"] != "") {
    $args["gid"] = $gid = $formfields["gid"];
}

if (isset($formfields["imagename"]) && $formfields["imagename"] != "") {
    $args["imagename"] = $imaganame = $formfields["imagename"];
}

if (isset($formfields["description"]) && $formfields["description"] != "") {
    $args["description"] = $formfields["description"];
}

$args["loadpart"] = 1;

$args["OS"] = 'Linux';

if (isset($formfields["version"]) && $formfields["version"] != "") {
    $args["version"]	= $formfields["version"];
}


if (isset($formfields["node_id"]) && $formfields["node_id"] != "") {
    $args["node_id"] = $formfields["node_id"];
}

$args["op_mode"] = 'pcvm';

# Filter booleans from checkboxes to 0 or 1.
if (isset($formfields["wholedisk"])) {
   $args["wholedisk"] = strcmp($formfields["wholedisk"], "Yep") ? 0 : 1;
}
if (isset($formfields["shared"])) {
   $args["shared"] = strcmp($formfields["shared"], "Yep") ? 0 : 1;
}
if (isset($formfields["global"])) {
   $args["global"] = strcmp($formfields["global"], "Yep") ? 0 : 1;
}

if (isset($formfields["max_concurrent"]) &&
    $formfields["max_concurrent"] != "") {
    $args["max_concurrent"] = $formfields["max_concurrent"];
}

if (isset($formfields["mbr_version"]) &&
    $formfields["mbr_version"] != "") {
    $args["mbr_version"] = $formfields["mbr_version"];
}

if (isset($formfields["reboot_waittime"]) &&
    $formfields["reboot_waittime"] != "") {
    $args["reboot_waittime"] = $formfields["reboot_waittime"];
}

$args["osfeatures"] = "ping,ssh,isup,linktest";

#
# Node.
#
unset($node);
unset($node_id);
if (isset($formfields["node_id"]) &&
    strcmp($formfields["node_id"], "")) {

    if (!TBvalid_node_id($formfields["node_id"])) {
	$errors["Node"] = "Invalid node name";
    }
    elseif (! ($node = Node::Lookup($formfields["node_id"]))) {
	$errors["Node"] = "Invalid node name";
    }
    elseif (!$node->AccessCheck($this_user, $TB_NODEACCESS_LOADIMAGE)) {
	$errors["Node"] = "Not enough permission";
    }
    else {
	$node_id = $node->node_id();
    }
}

if (!$pcvm_possible){
    $errors["No PCVM"] = "Emulab doesn't support PCVM machines";
}

# The mtype_* checkboxes are dynamically generated.
foreach ($mtypes_array as $type) {

    # Filter booleans from checkbox values.
    $checked = isset($formfields["mtype_$type"]) &&
	strcmp($formfields["mtype_$type"], "Yep") == 0;
    $args["mtype_$type"] = $checked ? "1" : "0";
}

#
# If any errors, respit the form with the current values and the
# error messages displayed. Iterate until happy.
# 
if (count($errors)) {
    SPITFORM($formfields, $errors);
    PAGEFOOTER();
    return;
}

#
# See if the user is trying anything funky.
# If so, we run this twice.
# The first time we are checking for a confirmation
# by putting up a form (we tramp their settings through
# hidden variables). The next time through the confirmation will be
# set. Or, the user can hit the 'back' button, 
# which will respit the form with their old values still filled in.
#

if (isset($canceled) && $canceled) {
    SPITFORM($formfields, 0);    
    PAGEFOOTER();
    return;
}


$imagename = $args["imagename"];
$args["path"] = $TBPROJ_DIR . $gid . "/" . $pid . "/images/" . $imagename . ".ndz";
$args["mtype_pcvm"] = 1;
$args["import_lock"] = 1;

#TODO: Ensure path is unique or take user input or do all the sophisticated checks stuff

if (! ($image = Image::NewImageId(1, $imagename, $args, $errors))) {
    # Always respit the form so that the form fields are not lost.
    # I just hate it when that happens so lets not be guilty of it ourselves.
    SPITFORM($formfields, $errors);
    PAGEFOOTER();
    return;

}
$imageid = $image->imageid();

$message_next = 'The image has been created. Use the link to get a script to run on "
	on the machine \n. Once that is done, click the "complete import" button on
	the image page. \n';

echo "<center><br />$message_next<br />";



SUBPAGESTART();
SUBMENUSTART("More Options");
if (! isset($node)) {
    $fooid = rawurlencode($imageid);
    WRITESUBMENUBUTTON("Edit this Image Descriptor",
		       "editimageid.php3?imageid=$fooid");
    WRITESUBMENUBUTTON("Delete this Image Descriptor",
		       "deleteimageid.php3?imageid=$fooid");
}
WRITESUBMENUBUTTON("Begin image import",
		   "importimage.php3");

WRITESUBMENUBUTTON("Image Descriptor list",
		   "showimageid_list.php3");
SUBMENUEND();

#
# Dump os_info record.
#
$image->Show();
SUBPAGEEND();

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
