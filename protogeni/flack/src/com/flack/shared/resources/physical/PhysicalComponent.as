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

package com.flack.shared.resources.physical
{
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.sites.FlackManager;

	/**
	 * Represents a physical component, like a node or link
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalComponent extends IdentifiableObject
	{
		[Bindable]
		public var manager:FlackManager;
		
		[Bindable]
		public var name:String;
		
		public var advertisement:String;
		
		/**
		 * 
		 * @param newManager Manager
		 * @param newId IDN-URN
		 * @param newName Short name
		 * @param newAdvertisement Advertisement
		 * 
		 */
		public function PhysicalComponent(newManager:FlackManager = null,
											newId:String = "",
											newName:String = "",
											newAdvertisement:String = null)
		{
			super(newId);
			manager = newManager;
			name = newName;
			advertisement = newAdvertisement;
		}
	}
}