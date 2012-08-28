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
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentStateTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	
	/**
	 * Gets the user's credential and slices
	 * 
	 * 1. If shouldResolveUser:
	 *     If using user credential: ResolveUserSaTask
	 *     If using slice credential: Start 2
	 * 2. If shouldGetSlices or using slice credential: For each slice: GetSliceTaskGroup
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetUserTaskGroup extends SerialTaskGroup
	{
		public var shouldResolveUser:Boolean;
		public var shouldGetExperiments:Boolean;
		
		/**
		 * 
		 * @param newUser User to get everything for
		 * @param newShouldResolveUser Resolve the user to get the list of slices, keys, etc.
		 * @param newShouldGetSlices Get the slices?
		 * 
		 */
		public function GetUserTaskGroup(newShouldResolveUser:Boolean = true,
										 newShouldGetExperiments:Boolean = true)
		{
			super(
				"Get user",
				"Gets all user-related information"
			);
			relatedTo.push(EmulabMain.user);
			forceSerial = true;
			
			shouldResolveUser = newShouldResolveUser;
			shouldGetExperiments = newShouldGetExperiments;
		}

		override protected function runStart():void
		{
			// First run
			if(tasks.length == 0)
			{
				if(shouldResolveUser)
					add(new ResolveUserTaskGroup());
				else if(shouldGetExperiments)
					getResources();
			}
			super.runStart();
		}
		
		override public function completedTask(task:Task):void
		{
			if(task is ResolveUserTaskGroup && shouldGetExperiments)
				getResources();
			super.completedTask(task);
		}
		
		private function getResources():void
		{
			if(EmulabMain.user.experiments.length == 0)
				afterComplete();
			else
			{
				var getExperiments:ParallelTaskGroup =
					new ParallelTaskGroup(
						"Get experiments",
						"Gets the experiments for the user"
					);
				for each(var exp:Experiment in EmulabMain.user.experiments.collection)
				{
					getExperiments.add(new EmulabExperimentStateTask(exp));
				}
				add(getExperiments);
			}
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			addMessage(
				"Finished",
				"Completed getting information for user " + SharedMain.user.name + " along with "+EmulabMain.user.experiments.length+" experiments.",
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_USER,
				SharedMain.user,
				FlackEvent.ACTION_POPULATED
			);
			super.afterComplete(addCompletedMessage);
		}
	}
}