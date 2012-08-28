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

package com.flack.geni.resources
{
	import com.flack.geni.resources.physical.DiskImageCollection;

	/**
	 * Collection of slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public class SliverTypeCollection
	{
		public var collection:Vector.<SliverType>;
		public function SliverTypeCollection()
		{
			collection = new Vector.<SliverType>();
		}
		
		public function add(type:SliverType):void
		{
			collection.push(type);
		}
		
		public function remove(type:SliverType):void
		{
			var idx:int = collection.indexOf(type);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(type:SliverType):Boolean
		{
			return collection.indexOf(type) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param name Name of sliver_type to get
		 * @return Sliver type with the given name
		 * 
		 */
		public function getByName(name:String):SliverType
		{
			for each(var type:SliverType in collection)
			{
				if(type.name == name)
					return type;
			}
			return null;
		}
		
		/**
		 * 
		 * @return All disk images listed in the sliver types
		 * 
		 */
		public function get DiskImages():DiskImageCollection
		{
			var results:DiskImageCollection = new DiskImageCollection();
			for each(var type:SliverType in collection)
			{
				for each(var image:DiskImage in type.diskImages.collection)
				{
					if(!results.contains(image))
						results.add(image);
				}
			}
			return results;
		}
	}
}