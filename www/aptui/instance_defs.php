<?php
#
# Copyright (c) 2006-2014 University of Utah and the Flux Group.
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
#
class Instance
{
    var	$instance;
    
    #
    # Constructor by lookup on unique index.
    #
    function Instance($uuid) {
	$safe_uuid = addslashes($uuid);

	$query_result =
	    DBQueryWarn("select * from apt_instances ".
			"where uuid='$safe_uuid'");

	if (!$query_result || !mysql_num_rows($query_result)) {
	    $this->instance = null;
	    return;
	}
	$this->instance = mysql_fetch_array($query_result);
    }
    # accessors
    function field($name) {
	return (is_null($this->instance) ? -1 : $this->instance[$name]);
    }
    function uuid()	    { return $this->field('uuid'); }
    function slice_uuid()   { return $this->field('slice_uuid'); }
    function creator()	    { return $this->field('creator'); }
    function creator_idx()  { return $this->field('creator_idx'); }
    function creator_uuid() { return $this->field('creator_uuid'); }
    function created()	    { return $this->field('created'); }
    function profile_idx()  { return $this->field('profile_idx'); }
    function status()	    { return $this->field('status'); }
    function manifest()	    { return $this->field('manifest'); }
    
    # Hmm, how does one cause an error in a php constructor?
    function IsValid() {
	return !is_null($this->instance);
    }

    # Lookup up an instance by idx. 
    function Lookup($idx) {
	$foo = new Instance($idx);

	if ($foo->IsValid()) {
            # Insert into cache.
	    return $foo;
	}	
	return null;
    }

    function LookupByCreator($token) {
	$safe_token = addslashes($token);

	$query_result =
	    DBQueryFatal("select uuid from apt_instances ".
			 "where creator_uuid='$safe_token'");

	if (! ($query_result && mysql_num_rows($query_result))) {
	    return null;
	}
	$row = mysql_fetch_row($query_result);
	$uuid = $row[0];
 	return Instance::Lookup($uuid);
    }

    #
    # Refresh an instance by reloading from the DB.
    #
    function Refresh() {
	if (! $this->IsValid())
	    return -1;

	$uuid = $this->uuid();

	$query_result =
	    DBQueryWarn("select * from apt_instances where uuid='$uuid'");
    
	if (!$query_result || !mysql_num_rows($query_result)) {
	    $this->instance  = NULL;
	    return -1;
	}
	$this->instance = mysql_fetch_array($query_result);
	return 0;
    }
}
?>
