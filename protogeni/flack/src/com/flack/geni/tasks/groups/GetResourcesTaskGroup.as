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
	import com.flack.geni.GeniCache;
	import com.flack.geni.GeniMain;
	import com.flack.geni.display.ChooseManagersToWatchWindow;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.tasks.process.ParseAdvertisementTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ch.ListComponentsChTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	
	import flash.utils.Dictionary;

	/**
	 * Gets the list of managers and/or lists their resources
	 * 
	 * 1. If shouldListManagers: ListComponentsChTask
	 * 2. If shouldGetResources: For each manager....
	 *  2a. GetVersionTask/GetVersionCmTask
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetResourcesTaskGroup extends ParallelTaskGroup
	{
		private var shouldListManagers:Boolean;
		private var shouldGetResources:Boolean;
		private var parseTasks:SerialTaskGroup;
		
		/**
		 * 
		 * @param listManagers Get the list of managers
		 * @param newShouldGetResources Get each of the managers' resources
		 * 
		 */
		public function GetResourcesTaskGroup(listManagers:Boolean = true,
											  newShouldGetResources:Boolean = true)
		{
			super(
				"Get resources",
				"Retreives GENI resources"
			);
			limitRunningCount = 5;
			forceSerial = true;
			shouldListManagers = listManagers;
			shouldGetResources = newShouldGetResources;
		}
		
		override protected function runStart():void
		{
			if(GeniMain.geniUniverse.user.authority.type != GeniAuthority.TYPE_EMULAB && GeniMain.geniUniverse.user.credential == null)
			{
				afterError(
					new TaskError(
						"No user certificate!",
						TaskError.CODE_PROBLEM
					)
				);
				return;
			}
			// First run
			if(tasks.length == 0)
			{
				if(shouldListManagers)
					add(new ListComponentsChTask(GeniMain.geniUniverse.user));
				else if(shouldGetResources)
					tryGetResources();
				else
					afterComplete();
			}
			super.runStart();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_UNIVERSE,
				null,
				FlackEvent.ACTION_POPULATED
			);
			super.afterComplete(addCompletedMessage);
		}
		
		override public function completedTask(task:Task):void
		{
			if(task is ListComponentsChTask && shouldGetResources)
			{
				if(tryGetResources())
					return;
			}
			super.completedTask(task);
		}
		
		// if true, waiting for user
		private function tryGetResources():Boolean
		{
			if(GeniMain.geniUniverse.managers.length == 0)
				afterComplete();
			else
			{
				if(GeniCache.shouldAskWhichManagersToWatch() && GeniMain.geniUniverse.user.authority.type != GeniAuthority.TYPE_EMULAB)
				{
					var askWindow:ChooseManagersToWatchWindow = new ChooseManagersToWatchWindow();
					askWindow.callAfter = getResources;
					askWindow.showWindow(true, true);
					return true;
				}
				else
				{
					var managersToWatch:Dictionary = GeniCache.getManagersToWatch();
					var managers:GeniManagerCollection = GeniMain.geniUniverse.managers.Clone;
					for(var managerId:String in managersToWatch)
					{
						if(managersToWatch[managerId] == false)
							managers.remove(managers.getById(managerId));
					}
					getResources(managers);
				}
			}
			return false;
		}
		
		private function getResources(managers:GeniManagerCollection):void
		{
			for each(var manager:GeniManager in managers.collection)
				add(new GetManagerTaskGroup(manager));
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
							"Parse advertisements",
							"Parses the advertised RSPECs one after the other",
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