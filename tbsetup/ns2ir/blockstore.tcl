
# -*- tcl -*-
#
# Copyright (c) 2000-2012 University of Utah and the Flux Group.
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
    $self set sclass {}
    $self set proto {}
    $self set type {}
    $self set role "unknown"
    #$self set parameters {}

    set ::GLOBALS::last_class $self
}

Blockstore instproc rename {old new} {
    $self instvar sim

    $sim rename_blockstore $old $new
}

Blockstore instproc set-class {newclass} {
    set bsclasses [list "SAN" "local"]

    if {[lsearch -exact $bsclasses $newclass] == -1} {
	perror "\[set-class] Class must be one of: [join $bsclasses {, }]"
	return
    }

    $self set sclass $newclass
    return
}

Blockstore instproc set-protocol {newproto} {
    set protocols [list "iSCSI" "FCoE" "SCSI" "SATA"]

    if {[lsearch -exact $protocols $newproto] == -1} {
	perror "\[set-protocol] Protocol must be one of: [join $protocols {, }]"
	return
    }

    $self set proto $newproto
    return
}

Blockstore instproc set-type {newtype} {
    var_import ::TBCOMPAT::sotypes

    if {[lsearch $sotypes $newtype] == -1} {
	perror "\[set-type] Invalid Storage Object type: $newtype"
	return
    }

    $self set type $newtype
    return
}

Blockstore instproc set-size {newsize} {
    set mindisksize [expr 2 ** 20]; # 1 MiB

    # Convert various input size strings to bytes.
    set convsize [convert_to_bytes $newsize]

    # Do some boundary checks.
    if { $convsize < $mindisksize } {
	perror "\[set-size] $convsize is smaller than allowed minimum (1 MiB)"
	return
    }
    if { $convsize % $mindisksize } {
	puts stderr "*** WARNING: \[set-size] blockstore size will be rounded down to the nearest MiB"
    }

    # Convert to MiB
    set convsize [expr $convsize >> 20]

    $self set size $convsize
    return
}

# updatedb DB
# This adds rows to the virt_blockstores and virt_blockstore_attributes 
# tables, corresponding to this storage object.
Blockstore instproc updatedb {DB} {
    var_import ::GLOBALS::pid
    var_import ::GLOBALS::eid
    var_import ::TBCOMPAT::sotypes
    $self instvar sim
    $self instvar node
    $self instvar type
    $self instvar size
    $self instvar role
    #$self instvar parameters

    if { $role == "unknown" } {
	puts stderr "*** WARNING: Disk role not set and unable to infer it."
    }

    set vb_fields [list "vname" "type" "role" "size"]
    set vb_values [list $self $type $role $size]

    #if { $parameters != "" } {
	#lappend fields "parameters"
	#lappend values $parameters
    #}
    #if { $command != "" } {
	#lappend fields "command"
	#lappend values $command
    #}

    # Update the DB
    spitxml_data "virt_blockstores" $vb_fields $vb_values

    #$sim spitxml_data "virt_agents" [list "vnode" "vname" "objecttype" ] [list $node $self $objtypes(DISK) ]
}

