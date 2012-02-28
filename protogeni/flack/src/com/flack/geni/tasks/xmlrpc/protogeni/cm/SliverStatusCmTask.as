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

package com.flack.geni.tasks.xmlrpc.protogeni.cm
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.VirtualComponent;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.utils.MathUtil;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Finds out the status of all the resources in the sliver.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class SliverStatusCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var continueUntilDone:Boolean;
		/**
		 * 
		 * @param newSliver Sliver to get status information for
		 * @param shouldContinueUntilDone Continue until status is finalized?
		 * 
		 */
		public function SliverStatusCmTask(newSliver:Sliver,
										   shouldContinueUntilDone:Boolean = true)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_SLIVERSTATUS,
				"Get sliver status @ " + newSliver.manager.hrn,
				"Gets the sliver status for component manager " + newSliver.manager.hrn + " on slice named " + newSliver.slice.hrn,
				"Get Sliver Status"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			
			sliver = newSliver;
			continueUntilDone = shouldContinueUntilDone;
			
			addMessage(
				"Waiting to get status...",
				"Waiting to get sliver status at " + sliver.manager.hrn,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sliver.slice.id.full);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				sliver.state = data.state;
				if(sliver.state == Sliver.STATE_STOPPED)
					sliver.status = Sliver.STATUS_STOPPED;
				else
					sliver.status = data.status;
				sliver.sliverIdToStatus[sliver.id.full] = sliver.status;
				for(var sliverId:String in data.details)
				{
					var sliverDetails:Object = data.details[sliverId];
					
					var virtualComponent:VirtualComponent = sliver.slice.getBySliverId(sliverId);
					if(virtualComponent != null)
					{
						virtualComponent.state = sliverDetails.state;
						if(virtualComponent.state == Sliver.STATE_STOPPED)
							virtualComponent.status = Sliver.STATUS_STOPPED;
						else
							virtualComponent.status = sliverDetails.status;
						sliver.sliverIdToStatus[virtualComponent.id.full] = virtualComponent.status;
						virtualComponent.error = sliverDetails.error;
					}
				}
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLIVER,
					sliver,
					FlackEvent.ACTION_STATUS
				);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					sliver.slice,
					FlackEvent.ACTION_STATUS
				);
				
				if(sliver.StatusFinalized)
				{
					addMessage(
						StringUtil.firstToUpper(sliver.status),
						"Status was received and is finished. Current status is " + sliver.status,
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					super.afterComplete(addCompletedMessage);
				}
				else
				{
					addMessage(
						StringUtil.firstToUpper(sliver.status) + "...",
						"Status was received but is still changing. Current status is " + sliver.status,
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					// Continue until the status is finished if desired
					if(continueUntilDone)
					{
						delay = MathUtil.randomNumberBetween(20, 60);
						runCleanup();
						start();
					}
					else
						super.afterComplete(addCompletedMessage);
				}
			}
			else
				faultOnSuccess();
		}
	}
}