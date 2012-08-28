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
	import com.flack.geni.resources.virtual.VirtualLinkCollection;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;

	public class MapLocation
	{
		public var latitude:Number;
		public var longitude:Number;
		
		public var locations:Vector.<PhysicalLocation> = new Vector.<PhysicalLocation>();
		
		public var physicalNodes:PhysicalNodeCollection;
		public var physicalLinks:PhysicalLinkCollection;
		public var virtualNodes:VirtualNodeCollection;
		public var virtualLinks:VirtualLinkCollection;
		
		public function MapLocation()
		{
		}
		
		/**
		 * 
		 * @param testLocations Locations we are testing for
		 * @return TRUE if the underlying location(s) is/are the same
		 * 
		 */
		public function sameLocationAs(testLocations:Vector.<PhysicalLocation>):Boolean
		{
			if(testLocations.length != locations.length)
				return false;
			for each(var testLocation:PhysicalLocation in testLocations)
			{
				if(locations.indexOf(testLocation) == -1)
					return false;
			}
			return true;
		}
	}
}