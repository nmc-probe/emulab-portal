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

package com.flack.emulab.resources.physical
{
	import com.flack.emulab.resources.NamedObject;
	import com.flack.emulab.resources.sites.EmulabManager;

	/**
	 * Resource as described by a manager's advertisement
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalNode extends NamedObject
	{
		public var manager:EmulabManager;
		[Bindable]
		public var available:Boolean;
		public var hardwareType:String = "";
		[Bindable]
		public var auxTypes:Vector.<String> = new Vector.<String>();
		
		/**
		 * 
		 * @param newManager Manager where the node is hosted
		 * @param newId IDN-URN id
		 * @param newName Short name for the node
		 * @param newAdvertisement Advertisement
		 * 
		 */
		public function PhysicalNode(newManager:EmulabManager = null,
									 newName:String = "")
		{
			super(newName);
			manager = newManager;
		}
	}
}