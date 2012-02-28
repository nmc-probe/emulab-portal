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
	import com.flack.shared.resources.sites.FlackManager;

	/**
	 * Federated ProtoGENI manager
	 * 
	 * @author mstrum
	 * 
	 */
	public class ProtogeniComponentManager extends GeniManager
	{
		/**
		 * 
		 * @param newId IDN-URN
		 * 
		 */
		public function ProtogeniComponentManager(newId:String)
		{
			super(FlackManager.TYPE_PROTOGENI, ApiDetails.API_PROTOGENI, newId);
			supportsDelayNodes = true;
		}
		
		override public function makeValidClientIdFor(value:String):String
		{
			return value.replace(".", "");
		}
	}
}