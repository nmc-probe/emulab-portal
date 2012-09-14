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

package com.flack.geni.resources.virtual
{
	/**
	 * Collection of slices
	 * 
	 * @author mstrum
	 * 
	 */
	public final class SliceCollection
	{
		public var collection:Vector.<Slice>;
		public function SliceCollection()
		{
			collection = new Vector.<Slice>();
		}
		
		public function add(slice:Slice):void
		{
			collection.push(slice);
		}
		
		public function remove(slice:Slice):void
		{
			var idx:int = collection.indexOf(slice);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(slice:Slice):Boolean
		{
			return collection.indexOf(slice) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Slice with the given ID
		 * 
		 */
		public function getById(id:String):Slice
		{
			for each(var existing:Slice in collection)
			{
				if(existing.id.full == id)
					return existing;
			}
			return null;
		}
		
		/**
		 * 
		 * @param name Slice name
		 * @return Slice with the given name
		 * 
		 */
		public function getByName(name:String):Slice
		{
			for each(var existing:Slice in collection)
			{
				if(existing.Name == name)
					return existing;
			}
			return null;
		}
		
		/**
		 * 
		 * @return Nodes from all the slices
		 * 
		 */
		public function get Nodes():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var existing:Slice in collection)
			{
				for each(var node:VirtualNode in existing.nodes.collection)
					nodes.add(node);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @return Links from all the slices
		 * 
		 */
		public function get Links():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var existing:Slice in collection)
			{
				for each(var link:VirtualLink in existing.links.collection)
					links.add(link);
			}
			return links;
		}
	}
}