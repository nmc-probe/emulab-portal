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
	 * Collection of hardware types
	 * @author mstrum
	 * 
	 */
	public class HardwareTypeCollection
	{
		public var collection:Vector.<HardwareType>;
		public function HardwareTypeCollection()
		{
			collection = new Vector.<HardwareType>();
		}
		
		public function add(ht:HardwareType):void
		{
			collection.push(ht);
		}
		
		public function remove(ht:HardwareType):void
		{
			var idx:int = collection.indexOf(ht);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(ht:HardwareType):Boolean
		{
			return collection.indexOf(ht) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param name Hardware type name
		 * @return Hardware type matching the name
		 * 
		 */
		public function getByName(name:String):HardwareType
		{
			for each(var ht:HardwareType in collection)
			{
				if(ht.name == name)
					return ht;
			}
			return null;
		}
	}
}