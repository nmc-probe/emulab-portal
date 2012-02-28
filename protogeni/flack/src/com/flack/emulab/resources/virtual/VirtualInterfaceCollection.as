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

package com.flack.emulab.resources.virtual
{
	/**
	 * Collection of slices
	 * 
	 * @author mstrum
	 * 
	 */
	public final class VirtualInterfaceCollection
	{
		public var collection:Vector.<VirtualInterface>;
		public function VirtualInterfaceCollection()
		{
			collection = new Vector.<VirtualInterface>();
		}
		
		public function add(slice:VirtualInterface):void
		{
			collection.push(slice);
		}
		
		public function remove(slice:VirtualInterface):void
		{
			var idx:int = collection.indexOf(slice);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(slice:VirtualInterface):Boolean
		{
			return collection.indexOf(slice) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get Clone():VirtualInterfaceCollection
		{
			var ifaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
			for each(var iface:VirtualInterface in collection)
				ifaces.add(iface);
			return ifaces;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Slice with the given ID
		 * 
		 */
		public function getByName(name:String):VirtualInterface
		{
			for each(var existing:VirtualInterface in collection)
			{
				if(existing.name == name)
					return existing;
			}
			return null;
		}
		
		public function get Links():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var testInterface:VirtualInterface in collection)
			{
				if(!links.contains(testInterface.link))
					links.add(testInterface.link);
			}
			return links;
		}
		
		public function get Nodes():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testInterface:VirtualInterface in collection)
			{
				if(!nodes.contains(testInterface.node))
					nodes.add(testInterface.node);
			}
			return nodes;
		}
	}
}