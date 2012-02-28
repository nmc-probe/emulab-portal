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

package com.flack.geni.resources.physical
{	
	/**
	 * Collection of interfaces from a physical node
	 * 
	 * @author mstrum
	 * 
	 */
	public final class PhysicalInterfaceCollection
	{
		public var collection:Vector.<PhysicalInterface>;
		public function PhysicalInterfaceCollection()
		{
			collection = new Vector.<PhysicalInterface>();
		}
		
		public function add(ni:PhysicalInterface):void
		{
			collection.push(ni);
		}
		
		public function remove(vi:PhysicalInterface):void
		{
			var idx:int = collection.indexOf(vi);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(vi:PhysicalInterface):Boolean
		{
			return collection.indexOf(vi) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @param exact Should the ID be exact? Should be FALSE if only a portion of the IDN-URN is known
		 * @return Matching interface
		 * 
		 */
		public function getById(id:String,
								exact:Boolean = true):PhysicalInterface
		{
			for each(var ni:PhysicalInterface in collection)
			{
				if(ni.id.full == id)
					return ni;
				if(!exact && ni.id.full.indexOf(id) != -1)
					return ni;
			}
			return null;
		}
		
		/**
		 * 
		 * @return All links from the interfaces
		 * 
		 */
		public function get Links():PhysicalLinkCollection
		{
			var ac:PhysicalLinkCollection = new PhysicalLinkCollection();
			for each(var ni:PhysicalInterface in collection)
			{
				for each(var l:PhysicalLink in ni.links.collection)
					ac.add(l);
			}
			return ac;
		}
		
		/**
		 * 
		 * @return All nodes hosting the interfaces
		 * 
		 */
		public function get Nodes():PhysicalNodeCollection
		{
			var ac:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each(var ni:PhysicalInterface in collection)
			{
				if(!ac.contains(ni.owner))
					ac.add(ni.owner);
			}
			return ac;
		}
		
		/**
		 * 
		 * @return All locations where the interfaces exist
		 * 
		 */
		public function get Locations():PhysicalLocationCollection
		{
			var ac:PhysicalLocationCollection = new PhysicalLocationCollection();
			for each(var ni:PhysicalInterface in collection)
			{
				if(!ac.contains(ni.owner.location))
					ac.add(ni.owner.location);
			}
			return ac;
		}
	}
}