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
	import com.flack.geni.resources.virtual.VirtualInterface;

	/**
	 * Properties of a link
	 * 
	 * @author mstrum
	 * 
	 */
	public class PropertyCollection
	{
		public var collection:Vector.<Property>;
		public function PropertyCollection()
		{
			collection = new Vector.<Property>();
		}
		
		public function add(property:Property):void
		{
			collection.push(property);
		}
		
		public function remove(property:Property):void
		{
			var idx:int = collection.indexOf(property);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(property:Property):Boolean
		{
			return collection.indexOf(property) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param source Source virtual or physical interface
		 * @param dest Destination virtual or physical interface
		 * @return Property related to the source and destination
		 * 
		 */
		public function getFor(source:*, dest:*):Property
		{
			for each(var property:Property in collection)
			{
				if(property.source == source && property.destination == dest)
					return property;
			}
			return null;
		}
		
		/**
		 * Removes all properties using the given interface
		 * 
		 * @param iface Virtual interface to remove any properties for
		 * 
		 */
		public function removeAnyWithInterface(iface:VirtualInterface):void
		{
			for(var i:int = 0; i < collection.length; i++)
			{
				var property:Property = collection[i];
				if(property.source == iface || property.destination == iface)
				{
					remove(property);
					i--;
				}
			}
		}
		
		/**
		 * Returns whether the properties are set in both directions
		 * 
		 * @return TRUE if properties extend in both directions
		 * 
		 */
		public function get Duplex():Boolean
		{
			for(var i:int = 0; i < collection.length; i++)
			{
				var testProperty:Property = collection[i];
				if(getFor(testProperty.destination, testProperty.source) == null)
					return false;
			}
			return true;
		}
	}
}