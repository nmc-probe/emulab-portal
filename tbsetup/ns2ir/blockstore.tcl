
# -*- tcl -*-
#
# Copyright (c) 2012 University of Utah and the Flux Group.
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

######################################################################
# blockstore.tcl
#
# This class defines the blockstore storage object.
#
######################################################################

Class Blockstore -superclass NSObject

Blockstore instproc init {s} {
    global ::GLOBALS::last_class

    $self set sim $s
    $self set node {}
    $self set type {}
    $self set size 0
    $self set type {}
    $self set role "unknown"

    # storage attributes (class, protocol, etc.)
    $self instvar attributes
    array set attributes {}

    set ::GLOBALS::last_class $self
}

Blockstore instproc rename {old new} {
    $self instvar sim

    $sim rename_blockstore $old $new
}

Blockstore instproc set-class {newclass} {
    var_import ::TBCOMPAT::soclasses
    $self instvar attributes

    if {![info exists soclasses($newclass)]} {
	perror "\[set-class] Invalid storage class: $newclass"
	return
    }

    $self set attributes(class) $newclass
    return
}

Blockstore instproc set-protocol {newproto} {
    var_import ::TBCOMPAT::soprotocols
    $self instvar attributes

    if {![info exists soprotocols($newproto)]} {
	perror "\[set-protocol] Invalid storage protocol: $newproto"
	return
    }

    $self set attributes(protocol) $newproto
    return
}

Blockstore instproc set-type {newtype} {
    var_import ::TBCOMPAT::sotypes

    if {![info exists sotypes($newtype)]} {
	perror "\[set-type] Invalid storage object type: $newtype"
	return
    }

    $self set type $type
    return
}

Blockstore instproc set-size {newsize} {
    set mindisksize 1; # 1 MiB

    # Convert various input size strings to mebibytes.
    set convsize [convert_to_mebi $newsize]

    # Do some boundary checks.
    if { $convsize < $mindisksize } {
	perror "\[set-size] $newsize is smaller than allowed minimum (1 MiB)"
	return
    }

    $self set size $convsize
    return
}


# Create a node object to represent the host that contains this blockstore,
# or return it if it already exists.
Blockstore instproc get_node {} {
    $self instvar sim
    $self instvar node

    if {$node != {}} {
	return $node
    }

    # Allocate parent host and bind to it.
    set hname "sanhost-${self}"
    uplevel "#0" "set $hname [$sim node]"
    $hname set subnodehost 1
    $hname set subnodechild $self

    # Return parent node object.
    return $hname
}

# updatedb DB
# This adds rows to the virt_blockstores and virt_blockstore_attributes 
# tables, corresponding to this storage object.
Blockstore instproc updatedb {DB} {
    var_import ::GLOBALS::pid
    var_import ::GLOBALS::eid
    $self instvar sim
    $self instvar node
    $self instvar type
    $self instvar size
    $self instvar role
    $self instvar attributes

    # XXX: role needs more thought...
    #if { $role == "unknown" } {
    #    puts stderr "*** WARNING: blockstore role not set and unable to infer it."
    #}

    # Emit top-level storage object stuff.
    set vb_fields [list "vname" "type" "role" "size"]
    set vb_values [list $self $type $role $size]
    $sim spitxml_data "virt_blockstores" $vb_fields $vb_values

    # Emit attributes.
    foreach key [lsort [array names attributes]] {
	set val $attributes($key)
	$sim spitxml_data "virt_blockstore_attributes" [list "vname" "attrkey" "attrvalue"] [list $self $key $val]
    }
}

