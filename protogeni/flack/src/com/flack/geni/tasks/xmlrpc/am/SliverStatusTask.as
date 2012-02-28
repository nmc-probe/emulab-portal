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

package com.flack.geni.tasks.xmlrpc.am
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.VirtualComponent;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.MathUtil;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Gets the status of the resources in the sliver.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class SliverStatusTask extends AmXmlrpcTask
	{
		public var sliver:Sliver;
		/**
		 * Keep running until status is final
		 */
		public var continueUntilDone:Boolean;
		/**
		 * 
		 * @param newSliver Sliver to get status for
		 * @param shouldContinueUntilDone Continue running until status is finalized?
		 * 
		 */
		public function SliverStatusTask(newSliver:Sliver,
										 shouldContinueUntilDone:Boolean = true)
		{
			super(
				newSliver.manager.api.url,
				AmXmlrpcTask.METHOD_SLIVERSTATUS,
				newSliver.manager.api.version,
				"Get sliver status @ " + newSliver.manager.hrn,
				"Getting the sliver status for aggregate manager " + newSliver.manager.hrn + " on slice named " + newSliver.slice.Name,
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
			addOrderedField(sliver.slice.id.full);
			addOrderedField([sliver.slice.credential.Raw]);
			if(apiVersion > 1)
				addOrderedField({});
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Sanity check for AM API 2+
			if(apiVersion > 1)
			{
				if(genicode != AmXmlrpcTask.GENICODE_SUCCESS)
				{
					faultOnSuccess();
					return;
				}
			}
			
			try
			{
				sliver.status = data.geni_status;
				sliver.id = new IdnUrn(data.geni_urn);
				sliver.sliverIdToStatus[sliver.id.full] = sliver.status;
				for each(var componentObject:Object in data.geni_resources)
				{
					var sliverComponent:VirtualComponent = sliver.slice.getBySliverId(componentObject.geni_urn);
					if(sliverComponent != null)
					{
						sliverComponent.status = componentObject.geni_status;
						sliver.sliverIdToStatus[sliverComponent.id.full] = sliverComponent.status;
						
						sliverComponent.error = componentObject.geni_error;
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
			catch(e:Error)
			{
				afterError(
					new TaskError(
						StringUtil.errorToString(e),
						TaskError.CODE_UNEXPECTED,
						e
					)
				);
			}
		}
	}
}