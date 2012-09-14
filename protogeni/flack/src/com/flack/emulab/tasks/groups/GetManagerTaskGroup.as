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

package com.flack.emulab.tasks.groups
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.tasks.xmlrpc.node.EmulabNodeGetListTask;
	import com.flack.shared.tasks.SerialTaskGroup;
	
	/**
	 * Gets version information and resources for a manager
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetManagerTaskGroup extends SerialTaskGroup
	{
		/**
		 * 
		 * @param taskManager Manager to get
		 * 
		 */
		public function GetManagerTaskGroup()
		{
			super(
				"Get " + EmulabMain.manager.hrn,
				"Retreives resources for " + EmulabMain.manager.hrn
			);
			forceSerial = true;
		}
		
		override protected function runStart():void
		{
			// First run
			if(tasks.length == 0)
			{
				add(new EmulabNodeGetListTask());
			}
			super.runStart();
		}
	}
}