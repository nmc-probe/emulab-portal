# -*- tcl -*-
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2012 University of Utah and the Flux Group.
# All rights reserved.
#

######################################################################
# disk.tcl
#
# This defines the local disk agent.
#
######################################################################

Class Disk -superclass NSObject

namespace eval GLOBALS {
    set new_classes(Disk) {}
}

Disk instproc init {s} {
    global ::GLOBALS::last_class

    $self set sim $s
    $self set node {}
    $self set type {}
    $self set mountpoint {}
    $self set parameters {}
    $self set command {}

    # Link simulator to this new object.
    $s add_disk $self

    set ::GLOBALS::last_class $self
}

Disk instproc rename {old new} {
    $self instvar sim

    $sim rename_disk $old $new
}

# updatedb DB
# This adds rows to the virt_trafgens table corresponding to this agent.
Disk instproc updatedb {DB} {
    var_import ::GLOBALS::pid
    var_import ::GLOBALS::eid
    var_import ::TBCOMPAT::objtypes
    $self instvar node
    $self instvar type 
    $self instvar mountpoint 
    $self instvar parameters
    $self instvar sim
    $self instvar command

    if {$node == {}} {
	perror "\[updatedb] $self has no node."
	return
    }

    set fields [list "vname" "diskname" "disktype" "mountpoint"]
    set values [list $node $self $type $mountpoint]

    if { $parameters != "" } {
	lappend fields "parameters"
	lappend values $parameters
    }
    if { $command != "" } {
	lappend fields "command"
	lappend values $command
    }

    # Update the DB
    spitxml_data "virt_node_disks" $fields $values

    $sim spitxml_data "virt_agents" [list "vnode" "vname" "objecttype" ] [list $node $self $objtypes(DISK) ]
}

