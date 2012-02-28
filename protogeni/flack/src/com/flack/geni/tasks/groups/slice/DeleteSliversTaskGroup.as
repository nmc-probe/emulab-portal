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
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.SliverCollection;
	import com.flack.geni.tasks.xmlrpc.am.DeleteSliverTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.DeleteSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.Task;
	
	import flash.display.Sprite;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	/**
	 * Deletes slivers, allowing user to cancel remaining slice operations on error
	 * 
	 * @author mstrum
	 * 
	 */
	public final class DeleteSliversTaskGroup extends ParallelTaskGroup
	{
		public var slivers:SliverCollection;
		public var askOnError:Boolean;
		public var waitingForUser:Boolean = false;
		public var ignoreUncreated:Boolean;
		/**
		 * 
		 * @param deleteSlivers Slivers to delete
		 * @param askUserOnError Ask user to continue if an error occurs?
		 * @param shouldIgnoreUncreated Skip slivers which don't have manifests
		 * 
		 */
		public function DeleteSliversTaskGroup(deleteSlivers:SliverCollection, askUserOnError:Boolean = true, shouldIgnoreUncreated:Boolean = true)
		{
			super(
				"Delete"+(deleteSlivers == null ? "" : " "+deleteSlivers.length)+" sliver(s)",
				"Deletes slivers not used anymore"
			);
			slivers = deleteSlivers;
			askOnError = askUserOnError;
			ignoreUncreated = shouldIgnoreUncreated;
			
			for(var i:int = 0; i < slivers.length; i++)
			{
				var deleteSliver:Sliver = slivers.collection[i];
				if(!ignoreUncreated || deleteSliver.Created)
				{
					if(deleteSliver.manager.api.type == ApiDetails.API_GENIAM)
						add(new DeleteSliverTask(deleteSliver));
					else
						add(new DeleteSliverCmTask(deleteSliver));
				}
				else
				{
					deleteSliver.removeFromSlice();
					i--;
				}
			}
		}
		
		override public function completeIfFinished(tryStarting:Boolean = true):void
		{
			if(waitingForUser)
				return;
			
			super.completeIfFinished(tryStarting);
		}
		
		// Allow user to cancel remaining actions if there is an error anywhere
		override public function erroredTask(task:Task):void
		{
			// Already asked and waiting...
			if(waitingForUser)
				return;
			
			// Don't prompt user
			if(!askOnError)
			{
				super.erroredTask(task);
				return;
			}
				
			waitingForUser = true;
			var name:String;
			if(task is DeleteSliverTask)
				name = (task as DeleteSliverTask).sliver.manager.hrn;
			else
				name = (task as DeleteSliverCmTask).sliver.manager.hrn;
			Alert.show(
				"Problem deleting sliver on " + name + ". Continue with the remaining actions?",
				"Continue?",
				Alert.YES|Alert.NO,
				FlexGlobals.topLevelApplication as Sprite,
				userChoice,
				null,
				Alert.YES
			);
		}
		
		public function userChoice(event:CloseEvent):void
		{
			waitingForUser = false;
			if(event.detail == Alert.YES)
			{
				addMessage(
					"User skipped failure",
					"User decided to continue with slice operations even after a delete failed",
					LogMessage.LEVEL_WARNING,
					LogMessage.IMPORTANCE_HIGH
				);
				completeIfFinished();
			}
			else
			{
				addMessage(
					"User canceled remaining",
					"User decided to cancel remaining slice operations after a delete failed",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				cancel();
			}
		}
	}
}