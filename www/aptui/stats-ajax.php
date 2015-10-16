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

#
# For the Cloudlab front page, to display some current stats.
#
$blob = array();

#
# Number of active experiments.
#
$query_result =
    DBQueryFatal("select count(uuid) from apt_instances");
if ($query_result) {
    $row = mysql_fetch_array($query_result);
    $blob["active_experiments"] = $row[0];
}

#
# Number Cloudlab projects.
#
$query_result =
    DBQueryFatal("select count(pid) from projects ".
                 "where approved=1 and genesis='cloudlab'");
if ($query_result) {
    $row = mysql_fetch_array($query_result);
    $blob["projects"] = $row[0];
}

#
# Number of users who have ever created an experiment.
#
$query_result =
    DBQueryFatal("(select distinct creator from apt_instance_history) ".
                 "union ".
                 "(select distinct creator from apt_instances)");
if ($query_result) {
    $blob["distinct_users"] = mysql_num_rows($query_result);
}

echo json_encode($blob);
