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
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.shared.resources.IdnUrn;

	/**
	 * Location with resources
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalLocation
	{
		static public const defaultLatitude:Number = 35.693829;
		static public const defaultLongitude:Number = -41.026843;
		
		public var latitude:Number;
		public var longitude:Number;
		
		public var country:String;
		[Bindable]
		public var name:String;
		
		public var nodes:PhysicalNodeCollection = new PhysicalNodeCollection();
		public var links:PhysicalLinkCollection = new PhysicalLinkCollection();
		
		public var managerId:IdnUrn;
		
		/**
		 * 
		 * @param newManager Manager
		 * @param lat Latitude
		 * @param lon Longitude
		 * @param newCountry Country
		 * @param newName Name
		 * 
		 */
		public function PhysicalLocation(newManager:GeniManager,
										 lat:Number = defaultLatitude,
										 lon:Number = defaultLongitude,
										 newCountry:String = "",
										 newName:String = "")
		{
			latitude = lat;
			longitude = lon;
			if(newManager != null)
				managerId = new IdnUrn(newManager.id.full);
			country = newCountry;
			name = newName;
		}
		
		/**
		 * 
		 * @return Collection of links leaving this location to another unique location
		 * 
		 */
		public function get LinksLeaving():PhysicalLinkCollection
		{
			var group:PhysicalLinkCollection = new PhysicalLinkCollection();
			for each (var link:PhysicalLink in links.collection)
			{
				for each(var nodeInterface:PhysicalInterface in link.interfaces.collection)
				{
					if(nodeInterface.owner.location != this && !group.contains(link))
					{
						group.add(link);
						break;
					}
				}
			}
			return group;
		}
	}
}