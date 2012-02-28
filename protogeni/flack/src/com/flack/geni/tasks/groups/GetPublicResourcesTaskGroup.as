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
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.tasks.http.PublicListManagersTask;
	import com.flack.geni.tasks.http.PublicListResourcesTask;
	import com.flack.geni.tasks.process.ParseAdvertisementTask;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;

	/**
	 * Discovers all resources advertised publicly
	 * 
	 * 1. PublicListManagersTask
	 * 2. If shouldGetResources: For each manager...
	 *  2a. PublicListResourcesTask
	 *  2b. ParseAdvertisementTask
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetPublicResourcesTaskGroup extends ParallelTaskGroup
	{
		private var shouldListManagers:Boolean;
		private var shouldGetResources:Boolean;
		private var parseTasks:SerialTaskGroup;
		
		/**
		 * 
		 * @param listManagers Download the list of managers
		 * @param newShouldGetResources Download each of the managers' public RSPEC
		 * 
		 */
		public function GetPublicResourcesTaskGroup(listManagers:Boolean = true,
													newShouldGetResources:Boolean = true)
		{
			super(
				"Discover resources publicly",
				"Retreives publicly-available GENI resources"
			);
			shouldListManagers = listManagers;
			shouldGetResources = newShouldGetResources;
		}
		
		override protected function runStart():void
		{
			// First run
			if(tasks.length == 0)
			{
				if(shouldListManagers)
					add(new PublicListManagersTask());
				else if(shouldGetResources)
					getResources();
				else
					super.afterComplete();
			}
			super.runStart();
		}
		
		override public function completedTask(task:Task):void
		{
			if(task is PublicListManagersTask && shouldGetResources)
				getResources();
			super.completedTask(task);
		}
		
		private function getResources():void
		{
			if(GeniMain.geniUniverse.managers.length == 0)
				afterComplete();
			else
			{
				for each(var manager:GeniManager in GeniMain.geniUniverse.managers.collection)
					add(new PublicListResourcesTask(manager));
			}
		}
		
		override public function add(task:Task):void
		{
			// put the advertisement parsing in their own serial group
			if(task is ParseAdvertisementTask)
			{
				if(parseTasks == null)
				{
					parseTasks =
						new SerialTaskGroup(
							"Parse RSPECs",
							"Parse RSPECs",
							"",
							null,
							true
						);
					super.add(parseTasks);
				}
				parseTasks.add(task);
			}
			else
				super.add(task);
		}
	}
}