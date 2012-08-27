/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

package com.flack.geni.plugins
{
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;

	public interface SliverTypeInterface
	{
		function get Name():String;
		// Optional
		function get namespace():Namespace;
		function get schema():String;
		
		function get Clone():SliverTypeInterface;
		
		function applyToSliverTypeXml(node:VirtualNode, xml:XML):void;
		function applyFromAdvertisedSliverTypeXml(node:PhysicalNode, xml:XML):void;
		function applyFromSliverTypeXml(node:VirtualNode, xml:XML):void;
		
		// Hooks
		function interfaceRemoved(iface:VirtualInterface):void;
		function interfaceAdded(iface:VirtualInterface):void;
		function canAdd(node:VirtualNode):Boolean;
		
		// List of strings when listing sliver type values
		function get SimpleList():ArrayCollection;
		
		// Optional custom node sliver type options interface
		function get Part():SliverTypePart;
	}
}