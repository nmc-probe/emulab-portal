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

package com.flack.geni.resources.sites.managers
{
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.shared.resources.sites.ApiDetails;
	
	/**
	 * PlanetLab implementation of the GENI AM API
	 * 
	 * @author mstrum
	 * 
	 */
	public class PlanetlabAggregateManager extends GeniManager
	{
		public var registryUrl:String;
		
		/**
		 * 
		 * @param newId IDN-URN
		 * 
		 */
		public function PlanetlabAggregateManager(newId:String)
		{
			super(TYPE_PLANETLAB, ApiDetails.API_GENIAM, newId);
		}
	}
}