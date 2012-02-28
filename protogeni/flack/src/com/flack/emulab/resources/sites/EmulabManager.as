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

package com.flack.emulab.resources.sites
{
	import com.flack.emulab.resources.physical.PhysicalNodeCollection;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.resources.sites.FlackManager;

	/**
	 * Federated ProtoGENI manager
	 * 
	 * @author mstrum
	 * 
	 */
	public class EmulabManager extends FlackManager
	{
		[Bindable]
		public var nodes:PhysicalNodeCollection = new PhysicalNodeCollection();
		public function EmulabManager(newId:String)
		{
			super(FlackManager.TYPE_EMULAB, ApiDetails.API_EMULAB, newId);
			api.version = 0.1;
		}
		
		override public function makeValidClientIdFor(value:String):String
		{
			return value.replace(".", "");
		}
		
		override public function clear():void
		{
			super.clear();
			clearComponents();
		}
		
		public function clearComponents():void
		{
			nodes = new PhysicalNodeCollection();
		}
	}
}