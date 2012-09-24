/*
 * Copyright (c) 2008-2012 University of Utah and the Flux Group.
 * 
 * {{{GENIPUBLIC-LICENSE
 * 
 * GENI Public License
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and/or hardware specification (the "Work") to
 * deal in the Work without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Work, and to permit persons to whom the Work
 * is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Work.
 * 
 * THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
 * IN THE WORK.
 * 
 * }}}
 */

package com.flack.geni.tasks.groups.slice
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.SliverCollection;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.RedeemTicketCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.StartSliverCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.UpdateSliverCmTask;
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
	 * Runs update and starts the slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public final class UpdateSliversTaskGroup extends SerialTaskGroup
	{
		public var slivers:SliverCollection;
		public var rspec:Rspec;
		/**
		 * 
		 * @param updateSlivers Slivers to run an update on
		 * @param requestRspec Request RSPEC to send to each manager
		 * 
		 */
		public function UpdateSliversTaskGroup(updateSlivers:SliverCollection,
											   requestRspec:Rspec = null)
		{
			super(
				"Update "+updateSlivers.length+" sliver(s)",
				"Updates existing slivers with changes"
			);
			slivers = updateSlivers;
			rspec = requestRspec;
			
			for each(var updateSliver:Sliver in slivers.collection)
			{
				// Not part of the GENI AM API
				if(updateSliver.manager.api.type == ApiDetails.API_PROTOGENI)
				{
					if(updateSliver.manager.api.level == ApiDetails.LEVEL_FULL)
					{
						relatedTo.push(updateSliver);
						add(new UpdateSliverCmTask(updateSliver, rspec));
					}
				}
			}
		}
		
		// Allow user to cancel remaining actions if there is an error anywhere
		override public function erroredTask(task:Task):void
		{
			var msg:String = "";
			if(task is UpdateSliverCmTask)
				msg = " updating sliver on " + (task as UpdateSliverCmTask).sliver.manager.hrn;
			else if(task is RedeemTicketCmTask)
				msg = " redeeming ticket on " + (task as RedeemTicketCmTask).sliver.manager.hrn;
			else if(task is ParseRequestManifestTask)
				msg = " parsing the manifest on " + (task as ParseRequestManifestTask).sliver.manager.hrn;
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
					"User decided to continue with slice operations even after an update failed",
					LogMessage.LEVEL_WARNING
				);
				runStart();
			}
			else
			{
				addMessage("User canceled remaining", "User decided to cancel remaining slice operations after an update failed");
				cancel();
			}
		}
	}
}