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
	 * Collection of physical links
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalLinkCollection
	{
		public var collection:Vector.<PhysicalLink>;
		public function PhysicalLinkCollection()
		{
			collection = new Vector.<PhysicalLink>();
		}
		
		public function add(link:PhysicalLink):void
		{
			collection.push(link);
		}
		
		public function remove(link:PhysicalLink):void
		{
			var idx:int = collection.indexOf(link);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(link:PhysicalLink):Boolean
		{
			return collection.indexOf(link) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param capacity Minimum capacity
		 * @return Links with at least the given capacity
		 * 
		 */
		public function getByMinimumCapacity(capacity:Number):PhysicalLinkCollection
		{
			var group:PhysicalLinkCollection = new PhysicalLinkCollection();
			for each (var l:PhysicalLink in collection)
			{
				if(l.Capacity >= capacity)
					group.add(l);
			}
			return group;
		}
		
		/**
		 * 
		 * @param type Link type
		 * @return Links matching the given type
		 * 
		 */
		public function getByType(type:String):PhysicalLinkCollection
		{
			var group:PhysicalLinkCollection = new PhysicalLinkCollection();
			for each (var l:PhysicalLink in collection)
			{
				for each (var nt:String in l.linkTypes)
				{
					if(nt == type)
					{
						group.add(l);
						break;
					}
				}
			}
			return group;
		}
		
		/**
		 * 
		 * @return New instance of this collection
		 * 
		 */
		public function get Clone():PhysicalLinkCollection
		{
			var clone:PhysicalLinkCollection = new PhysicalLinkCollection();
			for each(var l:PhysicalLink in collection)
				clone.add(l);
			return clone;
		}
		
		/**
		 * 
		 * @return All interfaces from the links
		 * 
		 */
		public function get Interfaces():PhysicalInterfaceCollection
		{
			var interfaces:PhysicalInterfaceCollection = new PhysicalInterfaceCollection();
			for each(var link:PhysicalLink in collection)
			{
				for each(var iface:PhysicalInterface in link.interfaces.collection)
				{
					if(!interfaces.contains(iface))
						interfaces.add(iface);
				}
			}
			return interfaces;
		}
		
		/**
		 * 
		 * @return Maximum capacity of any link
		 * 
		 */
		public function get MaximumCapacity():Number
		{
			var max:Number = 0;
			for each(var link:PhysicalLink in collection)
			{
				var linkCapacity:Number = link.Capacity;
				if(linkCapacity > max)
					max = linkCapacity;
			}
			return max;
		}
		
		/**
		 * 
		 * @return All of the link types
		 * 
		 */
		public function get Types():Vector.<String>
		{
			var types:Vector.<String> = new Vector.<String>();
			for each(var link:PhysicalLink in collection)
			{
				for each(var linkType:String in link.linkTypes)
				{
					if(types.indexOf(linkType) == -1)
						types.push(linkType);
				}
			}
			return types.sort(
				function compareTypes(a:String, b:String):Number
				{
					if(a < b)
						return -1;
					else if(a == b)
						return 0;
					else
						return 1;
				});
		}
	}
}