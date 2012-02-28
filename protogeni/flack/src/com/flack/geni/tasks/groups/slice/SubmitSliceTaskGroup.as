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

package com.flack.geni.tasks.groups.slice
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.SliverCollection;
	import com.flack.geni.tasks.process.GenerateRequestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.GetUserKeysSaTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	
	import flash.display.Sprite;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	/**
	 * Deletes, creates, and updates slivers based on changes to the slice.
	 * 
	 * On error: User is prompted whether to continue or cancel.
	 * If user cancels, user is prompted on whether to delete resources from slice in unknown state
	 * 
	 * @author mstrum
	 * 
	 */
	public final class SubmitSliceTaskGroup extends SerialTaskGroup
	{
		public var slice:Slice;
		
		public var deleteSlivers:SliverCollection;
		public var updateSlivers:SliverCollection;
		public var newSlivers:SliverCollection;
		
		public var requestRspec:Rspec;
		
		private var comfirmWithUser:Boolean;
		private var deletingAfterProblem:Boolean = false;
		private var prompting:Boolean = false;
		
		/**
		 * 
		 * @param submitSlice Slice to submit changes for
		 * @param shouldConfirmWithUser Ask user to confirm actions that will be taken?
		 * 
		 */
		public function SubmitSliceTaskGroup(submitSlice:Slice,
											 shouldConfirmWithUser:Boolean = true)
		{
			super(
				"Submit " + submitSlice.Name,
				"Submiting the slice named " + submitSlice.Name + " to be allocated"
			);
			relatedTo.push(submitSlice);
			slice = submitSlice;
			comfirmWithUser = shouldConfirmWithUser;
		}
		
		override protected function runStart():void
		{
			// First run
			if(tasks.length == 0)
			{
				// Can't try to submit a slice which is empty, delete it
				if(slice.nodes.length == 0 && slice.links.length == 0 && slice.slivers.Created.length == 0)
				{
					afterError(
						new TaskError(
							"Slice cannot be empty when submitting. Either create a new slice or delete the old slice.",
							TaskError.CODE_PROBLEM
						)
					);
					return;
				}
				
				// Invalidate the slice
				slice.markStaged();
				
				addMessage(
					"Generating request",
					slice.toString(),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				// Get the RSPEC which will be submitted
				var generateNewRspec:GenerateRequestTask = new GenerateRequestTask(slice);
				generateNewRspec.start();
				if(generateNewRspec.Status != Task.STATUS_SUCCESS)
				{
					afterError(generateNewRspec.error);
					return;
				}
				requestRspec = generateNewRspec.requestRspec;
				addMessage(
					"Generated request",
					requestRspec.document,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				// Build up slivers which need to be created/deleted/updated
				var newManagers:GeniManagerCollection = slice.nodes.Managers;
				deleteSlivers = new SliverCollection();
				updateSlivers = new SliverCollection();
				newSlivers = new SliverCollection();
				for each(var existingSliver:Sliver in slice.slivers.collection)
				{
					if(existingSliver.Created)
					{
						if(newManagers.contains(existingSliver.manager))
							updateSlivers.add(existingSliver);
						else
							deleteSlivers.add(existingSliver);
						newManagers.remove(existingSliver.manager);
					}
					else
						newSlivers.add(existingSliver);
				}
				for each(var newManager:GeniManager in newManagers.collection)
				{
					if(slice.slivers.getByManager(newManager) == null)
					{
						var newSliver:Sliver = new Sliver(slice, newManager);
						slice.slivers.add(newSliver);
						newSlivers.add(newSliver);
					}
				}
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					slice
				);
				
				// Add tasks to be run...
				if(tryApplyChanges())
					return;
			}
			super.runStart();
		}
		
		private function tryApplyChanges():Boolean
		{
			if(comfirmWithUser)
			{
				var submitMsg:String = "Continue with the following actions?";
				var i:int = 0;
				if(newSlivers.length > 0)
				{
					submitMsg += "\nCreate " + newSlivers.length + " new sliver" + (newSlivers.length ? "s" : "");
					for(i = 0; i < newSlivers.length; i++)
						submitMsg += "\n\t@ " + newSlivers.collection[i].manager.hrn;
				}
				if(updateSlivers.length > 0)
				{
					submitMsg += "\nUpdate " + updateSlivers.length + " existing sliver" + (updateSlivers.length ? "s" : "");
					for(i = 0; i < updateSlivers.length; i++)
						submitMsg += "\n\t@ " + updateSlivers.collection[i].manager.hrn;
				}
				if(deleteSlivers.length > 0)
				{
					submitMsg += "\nDelete " + deleteSlivers.length + " existing sliver" + (deleteSlivers.length ? "s" : "");
					for(i = 0; i < deleteSlivers.length; i++)
						submitMsg += "\n\t@ " + deleteSlivers.collection[i].manager.hrn;
				}
				Alert.show(
					submitMsg,
					"Continue?",
					Alert.YES|Alert.NO,
					FlexGlobals.topLevelApplication as Sprite,
					continueChoice
					);
				return true;
			}
			else
				applyChanges();
			return false;
		}
		
		private function continueChoice(e:CloseEvent):void
		{
			if(e.detail == Alert.YES)
				applyChanges();
			else
				cancel();
		}
		
		private function applyChanges():void
		{
			if(GeniMain.geniUniverse.user.authority != null)
				add(new GetUserKeysSaTask(GeniMain.geniUniverse.user, false));
			if(deleteSlivers.length > 0)
				add(new DeleteSliversTaskGroup(deleteSlivers));
			if(updateSlivers.length > 0)
				add(new UpdateSliversTaskGroup(updateSlivers, requestRspec));
			if(newSlivers.length > 0)
				add(new CreateSliversTaskGroup(newSlivers, requestRspec));
			
			add(new RefreshSliceStatusTaskGroup(slice));
			
			super.runStart();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(prompting)
				return;
			if(deletingAfterProblem)
			{
				addMessage("Resources deleted", slice.toString());
				super.afterError(
					new TaskError(
						"Resources deleted after slice was found to be in an unknown state",
						TaskError.CODE_PROBLEM
					)
				);
			}
			else
			{
				addMessage("Submitted", slice.toString(), LogMessage.LEVEL_INFO, LogMessage.IMPORTANCE_HIGH);
				super.afterComplete(addCompletedMessage);
			}
		}
		
		// If any of the slice operation groups are canceled, the entire process has been canceled
		override public function canceledTask(task:Task):void
		{
			if(!deletingAfterProblem)
			{
				if(task is DeleteSliversTaskGroup
					|| task is UpdateSliversTaskGroup
					|| task is CreateSliversTaskGroup)
				{
					prompting = true;
					cancelRemainingTasks();
					notFullySubmitted();
				}
				else
					super.canceledTask(task);
			}
			else
				runStart();
		}
		
		override public function erroredTask(task:Task):void
		{
			if(!deletingAfterProblem)
			{
				if(task is DeleteSliversTaskGroup
					|| task is UpdateSliversTaskGroup
					|| task is CreateSliversTaskGroup)
				{
					prompting = true;
					cancelRemainingTasks();
					notFullySubmitted();
				}
				else
					super.erroredTask(task);
			}
			else
				runStart();
		}
		
		public function notFullySubmitted():void
		{
			// ask user if they would like to delete...
			Alert.show(
				"Slice was not submitted and processed correctly. Deallocate resources so that slice isn't in an unknown state?",
				"Deallocate?",
				Alert.YES|Alert.NO,
				FlexGlobals.topLevelApplication as Sprite,
				userChoice,
				null,
				Alert.YES
			);
		}
		
		public function userChoice(event:CloseEvent):void
		{
			prompting = false;
			if(event.detail == Alert.YES)
			{
				addMessage(
					"User removing slice",
					"User decided to remove the slice which is in an unknown state",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				deletingAfterProblem = true;
				
				// Run a delete at all managers
				var deleteSlivers:SliverCollection = new SliverCollection();
				for each(var deleteSliverInManager:GeniManager in GeniMain.geniUniverse.managers.collection)
				{
					if(deleteSliverInManager.Status == FlackManager.STATUS_VALID)
					{
						var deleteSliver:Sliver = new Sliver(slice, deleteSliverInManager);
						deleteSliver.manifest = new Rspec();
						deleteSlivers.add(deleteSliver);
					}
				}
				add(new DeleteSliversTaskGroup(deleteSlivers, false));
			}
			else
			{
				addMessage(
					"User didn't remove slice",
					"User decided to not delete slice which is in an unknown state",
					LogMessage.LEVEL_WARNING,
					LogMessage.IMPORTANCE_HIGH
				);
				
				afterError(
					new TaskError(
						"Slice in unkown state",
						TaskError.CODE_PROBLEM
					)
				);
			}
		}
	}
}