
# -*- tcl -*-
#
# Copyright (c) 2012-2013 University of Utah and the Flux Group.
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
# This class defines the blockstore storage object.  Note: Each
# blockstore object's finalize() method MUST be called AFTER all of
# the set-* calls, but BEFORE the updatedb() method.  Generally,
# finalize() should be called once it is clear that no other set-*
# methods will be called; before the object is used.  E.g., the
# sim.tcl code calls finalize() for all blockstore object near the top
# of the run() method.
#
######################################################################

Class Blockstore -superclass NSObject

namespace eval GLOBALS {
    set new_classes(Blockstore) {}
}

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
    }

    set attributes(class) $newclass
    return
}

Blockstore instproc set-protocol {newproto} {
    var_import ::TBCOMPAT::soprotocols
    $self instvar attributes

    if {![info exists soprotocols($newproto)]} {
	perror "\[set-protocol] Invalid storage protocol: $newproto"
    }

    set attributes(protocol) $newproto
    return
}

Blockstore instproc set-type {newtype} {
    var_import ::TBCOMPAT::sotypes
    $self instvar type

    if {![info exists sotypes($newtype)]} {
	perror "\[set-type] Invalid storage object type: $newtype"
    }

    set type $type
    return
}

Blockstore instproc set-placement {newplace} {
    var_import ::TBCOMPAT::soplacementdesires
    $self instvar attributes

    set newplace [string toupper $newplace]
    if {![info exists soplacementdesires($newplace)]} {
	perror "Invalid placement specified: $newplace"
    }

    set attributes(placement) $newplace
    return
}

Blockstore instproc set-mount-point {newmount} {
    var_import ::TBCOMPAT::sodisallowedmounts
    $self instvar attributes
    $self instvar node

    # Keep the mount point path rules simple but strict:
    #  * Must start with a forward slash (absolute path)
    #  * Directory names must only consist of characters in: [a-zA-Z0-9_]
    #  * Two forward slashes in a row not allowed
    #  * Optionally end with a forward slash
    if {![regexp {^(/\w+){1,}/?$} $newmount]} {
	perror "Bad mountpoint: $newmount"
    }

    # Try to prevent user from shooting their own foot.
    if {[lsearch -exact $sodisallowedmounts $newmount] != -1} {
	perror "Cannot mount over important system directory: $newmount"
    }

    set attributes(mountpoint) $newmount
    return
}

Blockstore instproc set-size {newsize} {
    $self instvar node
    $self instvar size

    set mindisksize 1; # 1 MiB

    # Convert various input size strings to mebibytes.
    set convsize [convert_to_mebi $newsize]

    # Do some boundary checks.
    if { $convsize < $mindisksize } {
	perror "\[set-size] $newsize is smaller than allowed minimum (1 MiB)"
    }

    set size $convsize
    return
}

#
# Alias for procedure below
#
Blockstore instproc set-node {pnode} {
    return [$self set_fixed $pnode]
}

#
# Explicitly fix a blockstore to a node.
#
Blockstore instproc set_fixed {pnode} {
    $self instvar node

    if { [$pnode info class] != "Node" } {
	perror "Can only fix blockstores to a node object!"
    }
    
    set node $pnode
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
    set hname "blockhost-${self}"
    uplevel "#0" "set $hname [$sim node]"
    set node $hname
    $node set_hwtype "blockstore" 0 1 0    

    # Return parent node object.
    return $hname
}

# Do final (AFTER set-*, but BEFORE updatedb) validations and
# initializations.
Blockstore instproc finalize {} {
    var_import ::TBCOMPAT::sodefaultplacement
    var_import ::TBCOMPAT::sopartialplacements
    var_import ::TBCOMPAT::sofullplacements
    var_import ::TBCOMPAT::soplacementdesires
    var_import ::TBCOMPAT::sonodemounts
    $self instvar node
    $self instvar size
    $self instvar attributes

    # Instantiate blockstore pseudo-VM and attach to it if bstore 
    # isn't attached to anything at this point.
    if { $node == {} } {
	set dummy [$self get_node]
    }

    #
    # Local node hacks and stuff.  If the blockstore is fixed to
    # anything other than a blockstore pseudo-VM, then just attach a
    # desire to the parent node indicating a need for disk space.
    #
    # Also check for a bunch of incompatible specifications.
    #
    if {[$node set type] != "Blockstore"} {
	# Initialization for placement.
	if {![info exists attributes(placement)]} {
	    set attributes(placement) $sodefaultplacement
	} 
	set myplace $attributes(placement)
	set nodeplace "${node}:${myplace}"
	if {![info exists sopartialplacements($nodeplace)]} {
	    set sopartialplacements($nodeplace) 0
	}
	if {![info exists sofullplacements($nodeplace)]} {
	    set sofullplacements($nodeplace) 0
	}

	# Add a desire for space of the given placement type.
	set pldesire $soplacementdesires($myplace)
	if {$size != 0} {
	    set cursize [$node get-desire $pldesire]
	    if {$cursize == {}} {
		set cursize 0
	    }
	    $node add-desire $pldesire [expr $size + $cursize] 1
	    incr sopartialplacements($nodeplace) 1
	} else {
	    # add a token 1MiB desire, just to make sure something is there.
	    $node add-desire $pldesire 1 1
	    incr sofullplacements($nodeplace) 1
	}

	# Check that there is only one sysvol placement per node
	set systotal [expr $sopartialplacements($nodeplace) + \
			   $sofullplacements($nodeplace)]
	if { $myplace == "SYSVOL" && $systotal > 1 } {
	    perror "Only one sysvol placement allowed per node!"
	    return
	}

	# Sanity check for full placements.  There can be only one per node
	# per placement type.
	if { $sofullplacements($nodeplace) > 1 ||
	     ($sofullplacements($nodeplace) == 1 &&
	      $sopartialplacements($nodeplace) > 0) } {
	    perror "Full placement collision detected ($node:$myplace)!"
	    return
	}

	# Look for an incompatible mix of "ANY" and other placements (per-node).
	set srchres 0
	set allplacements [concat [array names sopartialplacements -glob "${node}:*"] [array names sofullplacements -glob "${node}:*"]]
	if {$myplace == "ANY"} {
	    set srchres [lsearch -exact -not $allplacements "${node}:ANY"]
	} else {
	    set srchres [lsearch -exact $allplacements "${node}:ANY"]
	}
	if {$srchres != -1} {
	    perror "Incompatible mix of 'ANY' and other placements ($node)!"
	    return
	}

    } else {
	if {[info exists attributes(placement)]} {
	    perror "Placement setting can only be used with a local blockstore."
	    return
	}
    }

    # Check for node mount collisions.
    if {[info exists attributes(mountpoint)]} {
	set mymount $attributes(mountpoint)
	if {![info exists sonodemounts($node)]} {
	    set sonodemounts($node) {}
	}
	# Look through all mount points for blockstores attached to the same
	# node as this blockstore.
	set mplist [lreplace [split $mymount   "/"] 0 0]
	foreach nodemount $sonodemounts($node) {
	    set nmlist [lreplace [split $nodemount "/"] 0 0]
	    set diff 0
	    # Look for any differences in path components.  If one is a 
	    # matching prefix of the other, then the mount is nested or
	    # identical.
	    foreach nmcomp $nmlist mpcomp $mplist {
		# Have we hit the end of the list for one or the other?
		if {$nmcomp == {} || $mpcomp == {}} {
		    break
		} elseif {$nmcomp != $mpcomp} {
		    set diff 1
		    break
		}
	    }
	    if {!$diff} {
		perror "Mount collision or nested mount detected on $node: $mymount, $nodemount"
		return
	    }
	}
	lappend sonodemounts($node) $mymount
    }

}

# updatedb DB
# This adds rows to the virt_blockstores and virt_blockstore_attributes 
# tables, corresponding to this storage object.
Blockstore instproc updatedb {DB} {
    var_import ::GLOBALS::pid
    var_import ::GLOBALS::eid
    var_import ::TBCOMPAT::sodesires
    $self instvar sim
    $self instvar node
    $self instvar type
    $self instvar size
    $self instvar role
    $self instvar attributes

    # XXX: blockstore role needs more thought...
    #if { $role == "unknown" } {
    #    puts stderr "*** WARNING: blockstore role not set and unable to infer it."
    #}

    # Emit top-level storage object stuff.
    set vb_fields [list "vname" "type" "role" "size" "fixed"]
    set vb_values [list $self $type $role $size $node]
    $sim spitxml_data "virt_blockstores" $vb_fields $vb_values

    # Emit attributes.
    foreach key [lsort [array names attributes]] {
	set val $attributes($key)
	set vba_fields [list "vname" "attrkey" "attrvalue" "isdesire"] 
	set vba_values [list $self $key $val]
	
	set isdesire [expr [info exists sodesires($key)] ? 1 : 0]
	lappend vba_values $isdesire

	$sim spitxml_data "virt_blockstore_attributes" $vba_fields $vba_values

    }
}
