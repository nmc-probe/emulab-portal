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

package com.flack.geni.tasks.groups
{
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.tasks.process.ParseAdvertisementTask;
	import com.flack.geni.tasks.xmlrpc.am.GetVersionTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.GetVersionCmTask;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	
	/**
	 * Gets version information and resources for a manager
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetManagerTaskGroup extends SerialTaskGroup
	{
		public var manager:GeniManager;
		
		/**
		 * 
		 * @param taskManager Manager to get
		 * 
		 */
		public function GetManagerTaskGroup(taskManager:GeniManager)
		{
			super(
				"Get " + taskManager.hrn,
				"Retreives resources for " + taskManager.id.full
			);
			manager = taskManager;
		}
		
		override protected function runStart():void
		{
			// First run
			if(tasks.length == 0)
			{
				if(manager.api.type == ApiDetails.API_GENIAM)
					add(new GetVersionTask(manager));
				else if(manager.api.type == ApiDetails.API_PROTOGENI)
					add(new GetVersionCmTask(manager));
			}
			super.runStart();
		}
		
		override public function add(task:Task):void
		{
			if(task is ParseAdvertisementTask)
			{
				// If part of a larger operation, add it to that operation to parse serially
				if(parent is GetResourcesTaskGroup)
				{
					parent.add(task);
					return;
				}
			}
			super.add(task);
		}
	}
}