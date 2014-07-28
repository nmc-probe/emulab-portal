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
    function Profile($token, $version = null) {
	$safe_profileid = addslashes($token);
	
	if (preg_match("/^\w+\-\w+\-\w+\-\w+\-\w+$/", $token)) {
	    $query_result =
		DBQueryWarn("select i.*,v.* from apt_profile_versions as v ".
			    "left join apt_profiles as i on ".
			    "     i.profileid=v.profileid ".
			    "where v.uuid='$token' and v.deleted is null");
	}
	elseif (is_null($version)) {
	    $query_result =
		DBQueryWarn("select i.*,v.* from apt_profiles as i ".
			    "left join apt_profile_versions as v on ".
			    "     v.profileid=i.profileid and ".
			    "     v.version=i.version ".
			    "where i.profileid='$safe_profileid'");
	}
	else {
	    $safe_version = addslashes($version);
	    $query_result =
	        DBQueryWarn("select i.*,v.* from apt_profile_versions as v ".
			    "left join apt_profiles as i on ".
			    "     i.profileid=v.profileid ".
			    "where v.profileid='$safe_profileid' and ".
			    "      v.version='$safe_version' and ".
			    "      v.deleted is null");
	}
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
    function profileid()    { return $this->field('profileid'); }
    function version()      { return $this->field('version'); }
    function creator()	    { return $this->field('creator'); }
    function creator_idx()  { return $this->field('creator_idx'); }
    function pid()	    { return $this->field('pid'); }
    function pid_idx()	    { return $this->field('pid_idx'); }
    function created()	    { return $this->field('created'); }
    function published()    { return $this->field('published'); }
    function deleted()	    { return $this->field('deleted'); }
    function uuid()	    { return $this->field('uuid'); }
    function ispublic()	    { return $this->field('public'); }
    function shared()	    { return $this->field('shared'); }
    function listed()	    { return $this->field('listed'); }
    function rspec()	    { return $this->field('rspec'); }
    function locked()	    { return $this->field('status'); }
    function status()	    { return $this->field('locked'); }
    function parent_profileid()    { return $this->field('parent_profileid'); }
    function parent_version()      { return $this->field('parent_version'); }

    # Private means only in the same project.
    function IsPrivate() {
	return !($this->ispublic() || $this->shared());
    }
    
    # Hmm, how does one cause an error in a php constructor?
    function IsValid() {
	return !is_null($this->profile);
    }

    # Lookup up a single profile by idx. 
    function Lookup($token, $version = null) {
	$foo = new Profile($token, $version);

	if ($foo->IsValid()) {
            # Insert into cache.
	    return $foo;
	}	
	return null;
    }

    function LookupByName($project, $name, $version = null) {
	$pid = $project->pid();
	$safe_name = addslashes($name);

	if (preg_match("/^\w+\-\w+\-\w+\-\w+\-\w+$/", $name)) {
	    return Profile::Lookup($name);
	}
	elseif (is_null($version)) {
	    $query_result =
		DBQueryWarn("select i.profileid,i.version ".
			    "  from apt_profiles as i ".
			    "left join apt_profile_versions as v on ".
			    "     v.profileid=i.profileid and ".
			    "     v.version=i.version ".
			    "where i.pid='$pid' and ".
			    "      i.name='$safe_name'");
	}
	else {
	    $safe_version = addslashes($version);
	    $query_result =
		DBQueryWarn("select i.profileid,i.version ".
			    "  from apt_profiles as i ".
			    "left join apt_profile_versions as v on ".
			    "     v.profileid=i.profileid ".
			    "where i.pid='$pid' and ".
			    "      i.name='$safe_name' and ".
			    "      v.version='$safe_version'");
	}
	if ($query_result && mysql_num_rows($query_result)) {
	    $row = mysql_fetch_row($query_result);
	    return Profile::Lookup($row[0], $row[1]);
	}
	return null;
    }

    #
    # Refresh an instance by reloading from the DB.
    #
    function Refresh() {
	if (! $this->IsValid())
	    return -1;

	$profileid = $this->profileid();
	$version   = $this->version();

	$query_result =
	    DBQueryWarn("select * from apt_profile_versions ".
			"where profileid='$profileid' and version='$version'");
    
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

	if ($this->ispublic()) {
	    $pid  = $this->pid();
	    $name = $this->name();
	    $vers = $this->version();
	    return "$APTBASE/p/$pid/$name/$vers";
	}
	else {
	    return "$APTBASE/p/$uuid";	    
	}
    }

    #
    # Is this profile the highest numbered version.
    # 
    function IsHead() {
	$profileid = $this->profileid();

	$query_result =
	    DBQueryWarn("select max(version) from apt_profile_versions ".
			"where profileid='$profileid'");
	if (!$query_result || !mysql_num_rows($query_result)) {
	    return -1;
	}
	$row = mysql_fetch_row($query_result);
	return ($this->version() == $row[0] ? 1 : 0);
    }
    #
    # Does this profile have more then one version (history).
    # 
    function HasHistory() {
	$profileid = $this->profileid();

	$query_result =
	    DBQueryWarn("select count(*) from apt_profile_versions ".
			"where profileid='$profileid'");
	if (!$query_result || !mysql_num_rows($query_result)) {
	    return -1;
	}
	$row = mysql_fetch_row($query_result);
	return ($row[0] > 1 ? 1 : 0);
    }
    #
    # A profile can be published if it is a > version then the most
    # recent published profile. 
    # 
    function CanPublish() {
	$profileid = $this->profileid();

	# Already published. Might support unpublish at some point.
	if ($this->published())
	    return 0;

	$query_result =
	    DBQueryWarn("select version from apt_profile_versions ".
			"where profileid='$profileid' and ".
			"      published is not null ".
			"order by version desc limit 1");
	if (!$query_result || !mysql_num_rows($query_result)) {
	    return -1;
	}
	$row = mysql_fetch_row($query_result);
	$vers = $row[0];
	
	return ($this->version() > $row[0] ? 1 : 0);
    }
    #
    # A profile can be modified if it is a >= version then the most
    # recent published profile. 
    # 
    function CanModify() {
	$profileid = $this->profileid();

	$query_result =
	    DBQueryWarn("select version from apt_profile_versions ".
			"where profileid='$profileid' and ".
			"      published is not null ".
			"order by version desc limit 1");
	if (!$query_result || !mysql_num_rows($query_result)) {
	    return -1;
	}
	$row = mysql_fetch_row($query_result);
	$vers = $row[0];
	
	return ($this->version() >= $row[0] ? 1 : 0);
    }
}
?>
