# -*- tcl -*-
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2006 University of Utah and the Flux Group.
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
    $self set name {}
    $self set type {}
    $self set mountpoint {}
    $self set params {}

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
    $self instvar name 
    $self instvar type 
    $self instvar mountpoint 
    $self instvar params 
    $self instvar sim

    if {$node == {}} {
	perror "\[updatedb] $self has no node."
	return
    }
    set progvnode $node

    #
    # if the attached node is a simulated one, we attach the
    # program to the physical node on which the simulation runs
    #
    if {$progvnode != "ops"} {
	if { [$node set simulated] == 1 } {
	    set progvnode [$node set nsenode]
	}
    }

    # Update the DB
    spitxml_data "virt_disk" [list "vnode" "vname" "name" "type" "mountpoint" "params"] [list $progvnode $self $name $type $mountpoint $params ]

    $sim spitxml_data "virt_agents" [list "vnode" "vname" "objecttype" ] [list $progvnode $self $objtypes(DISK) ]
}

