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
class Profile
{
    var	$profile;
    var $project;

    #
    # Constructor by lookup on unique index.
    #
    function Profile($idx) {
	$safe_idx = addslashes($idx);

	$query_result =
	    DBQueryWarn("select * from apt_profiles ".
			"where idx='$safe_idx'");

	if (!$query_result || !mysql_num_rows($query_result)) {
	    $this->profile = null;
	    return;
	}
	$this->profile = mysql_fetch_array($query_result);

	# Load lazily;
	$this->project    = null;
    }
    # accessors
    function field($name) {
	return (is_null($this->profile) ? -1 : $this->profile[$name]);
    }
    function name()	    { return $this->field('name'); }
    function idx()	    { return $this->field('idx'); }
    function creator()	    { return $this->field('creator'); }
    function creator_idx()  { return $this->field('creator_idx'); }
    function pid()	    { return $this->field('pid'); }
    function pid_idx()	    { return $this->field('pid_idx'); }
    function created()	    { return $this->field('created'); }
    function modified()	    { return $this->field('modified'); }
    function uuid()	    { return $this->field('uuid'); }
    function ispublic()	    { return $this->field('public'); }
    function shared()	    { return $this->field('shared'); }
    function listed()	    { return $this->field('listed'); }
    function weburi()	    { return $this->field('weburi'); }
    function description()  { return $this->field('description'); }
    function rspec()	    { return $this->field('rspec'); }
    
    # Hmm, how does one cause an error in a php constructor?
    function IsValid() {
	return !is_null($this->profile);
    }

    # Lookup up a single profile by idx. 
    function Lookup($idx) {
	$foo = new Profile($idx);

	if ($foo->IsValid()) {
            # Insert into cache.
	    return $foo;
	}	
	return null;
    }

    # Lookup by name/version. If no version, then return highest
    # numbered version.
    function LookupByName() {}

    #
    # Refresh an instance by reloading from the DB.
    #
    function Refresh() {
	if (! $this->IsValid())
	    return -1;

	$idx = $this->idx();

	$query_result =
	    DBQueryWarn("select * from apt_profiles where idx='$idx'");
    
	if (!$query_result || !mysql_num_rows($query_result)) {
	    $this->profile    = NULL;
	    $this->project    = null;
	    return -1;
	}
	$this->profile    = mysql_fetch_array($query_result);
	$this->project    = null;
	return 0;
    }

    #
    # URL.
    #
    function URL() {
	global $APTBASE;
	
	$uuid = $this->uuid();

	return "$APTBASE/p/$uuid";
    }
}
?>
