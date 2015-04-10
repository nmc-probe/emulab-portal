<?php
#
# Copyright (c) 2000-2015 University of Utah and the Flux Group.
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
chdir("..");
include("defs.php3");
chdir("apt");
include("quickvm_sup.php");
$page_title = "Cluster Status";

SPITHEADER(1);
echo "  <center><table>
    <tr>
      <td valign=middle align=left>Cloudlab Utah</td>
      <td valign=middle align=center>
	<img width=350
	   src='http://www.utah.cloudlab.us/node_usage/freenodes.svg'>
	</td>
    </tr>
    <tr>
      <td valign=middle align=left>APT (Utah)</td>
      <td valign=middle align=center>
	<img width=350
	   src='http://www.apt.emulab.net/node_usage/freenodes.svg'>
	</td>
    </tr>
    <tr>
      <td valign=middle align=left>Cloudlab Wisconsin</td>
      <td valign=middle align=center>
	<img width=350
	   src='http://www.wisc.cloudlab.us/node_usage/freenodes.svg'>
	</td>
    </tr>
    <tr>
      <td valign=middle align=left>Cloudlab Clemson</td>
      <td valign=middle align=center>
	<img width=350
	   src='http://www.clemson.cloudlab.us/node_usage/freenodes.svg'>
	</td>
    </tr>
    <tr>
      <td valign=middle align=left>Emulab PG</td>
      <td valign=middle align=center>
	<img width=350
	   src='http://www.emulab.net/node_usage/freenodes.svg'>
	</td>
    </tr>
  <table></center>\n";

SPITNULLREQUIRE();
SPITFOOTER();
?>
