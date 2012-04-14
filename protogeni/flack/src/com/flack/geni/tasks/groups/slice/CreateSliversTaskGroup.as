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
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.am.CreateSliverTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.CreateSliverCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.GetTicketCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.RedeemTicketCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.StartSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	
	import flash.display.Sprite;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	/**
	 * Allocate resources for the first time at a manager for a slice.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class CreateSliversTaskGroup extends SerialTaskGroup
	{
		public var slivers:SliverCollection;
		public var rspec:Rspec;
		/**
		 * 
		 * @param createSlivers Slivers to allocate resources at
		 * @param requestRspec RSPEC to send to each manager
		 * @param askToContinueOnFailure Ask the user to continue on failures? ... Not used???
		 * 
		 */
		public function CreateSliversTaskGroup(createSlivers:SliverCollection,
											   requestRspec:Rspec = null,
											   askToContinueOnFailure:Boolean = true)
		{
			super(
				"Create "+createSlivers.length+" sliver(s)",
				"Allocates new slivers"
			);
			slivers = createSlivers;
			rspec = requestRspec;
			
			for each(var newSliver:Sliver in slivers.collection)
			{
				if(newSliver.manager.api.type == ApiDetails.API_GENIAM)
					add(new CreateSliverTask(newSliver, rspec));
				else
				{
					if(newSliver.manager.api.level == ApiDetails.LEVEL_MINIMAL)
						add(new CreateSliverCmTask(newSliver, rspec));
					else
						add(new GetTicketCmTask(newSliver, rspec));
				}
			}
		}
		
		// Allow user to cancel remaining actions if there is an error anywhere
		override public function erroredTask(task:Task):void
		{
			var msg:String = "";
			if(task is CreateSliverCmTask)
				msg = " creating sliver on " + (task as CreateSliverCmTask).sliver.manager.hrn;
			else if(task is CreateSliverTask)
				msg = " creating sliver on " + (task as CreateSliverTask).sliver.manager.hrn;
			else if(task is ParseRequestManifestTask)
				msg = " parsing the manifest on " + (task as ParseRequestManifestTask).sliver.manager.hrn;
			else if(task is GetTicketCmTask)
				msg = " updating sliver on " + (task as GetTicketCmTask).sliver.manager.hrn;
			else if(task is RedeemTicketCmTask)
				msg = " redeeming ticket on " + (task as RedeemTicketCmTask).sliver.manager.hrn;
			else if(task is StartSliverCmTask)
				msg = " starting the sliver on " + (task as StartSliverCmTask).sliver.manager.hrn;
			Alert.show(
				"Problem" + msg + ". Continue with the remaining actions?",
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
			if(event.detail == Alert.YES)
			{
				addMessage(
					"User skipped failure",
					"User decided to continue with slice operations even after a create failed",
					LogMessage.LEVEL_WARNING,
					LogMessage.IMPORTANCE_HIGH
				);
				runStart();
			}
			else
			{
				addMessage(
					"User canceled remaining",
					"User decided to cancel remaining slice operations after a create failed",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				cancel();
			}
		}
	}
}