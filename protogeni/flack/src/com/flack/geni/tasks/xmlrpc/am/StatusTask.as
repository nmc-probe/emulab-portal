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

package com.flack.geni.tasks.xmlrpc.am
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.VirtualComponent;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.DateUtil;
	import com.flack.shared.utils.MathUtil;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Gets the status of the resources in the sliver.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class StatusTask extends AmXmlrpcTask
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
		public function StatusTask(newSliver:Sliver,
								   shouldContinueUntilDone:Boolean = true)
		{
			super(
				newSliver.manager.api.url,
				newSliver.manager.api.version < 3
					? AmXmlrpcTask.METHOD_SLIVERSTATUS : AmXmlrpcTask.METHOD_STATUS,
				newSliver.manager.api.version,
				"Get Status @ " + newSliver.manager.hrn,
				"Getting the status for aggregate manager " + newSliver.manager.hrn + " on slice named " + newSliver.slice.Name,
				"Get Status"
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
				if(apiVersion < 3)
					parseValueIntoSliverV12(data, sliver);
				else
				{
					for each(var val:* in data)
					{
						parseValueIntoSliverV3(val, sliver);
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
		
		private function parseValueIntoSliverV12(value:*, intoSliver:Sliver):void
		{
			sliver.status = data.geni_status;
			sliver.id = new IdnUrn(data.geni_urn);
			sliver.sliverIdToStatus[sliver.id.full] = sliver.status;
			for each(var componentObject:Object in data.geni_resources)
			{
				var sliverComponentId:String = componentObject.geni_urn;
				var sliverComponent:VirtualComponent = sliver.slice.getBySliverId(sliverComponentId);
				if(sliverComponent == null)
				{
					addMessage(
						"Node not found",
						"Node with sliver id " + sliverComponentId + " wasn't found in the sliver! " +
						"This may indicate that the manager failed to include the sliver id in the manifest.",
						LogMessage.LEVEL_FAIL,
						LogMessage.IMPORTANCE_HIGH,
						true
					);
					continue;
				}
				
				if(componentObject.geni_status == null)
					sliverComponent.status = sliver.status;
				else
					sliverComponent.status = componentObject.geni_status;
				sliver.sliverIdToStatus[sliverComponent.id.full] = sliverComponent.status;
				
				sliverComponent.error = componentObject.geni_error;
			}
		}
		
		private function parseValueIntoSliverV3(value:*, intoSliver:Sliver):void
		{
			sliver.id = new IdnUrn(data.geni_sliver_urn);
			sliver.expires = DateUtil.parseRFC3339(data.geni_expires);
			sliver.allocationStatus = data.geni_allocation_status;
			if(data.geni_error != null)
				sliver.error = data.geni_error;
			/*
			<others AM or method specific>
			<Provision returns geni_operational_status>
			*/
		}
	}
}