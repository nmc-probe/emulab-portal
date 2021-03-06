/*
 * Copyright (c) 2008-2013 University of Utah and the Flux Group.
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

package com.flack.geni.tasks.xmlrpc.protogeni.cm
{
	import com.flack.geni.resources.virt.AggregateSliver;
	import com.flack.geni.tasks.process.GenerateRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	
	/**
	 * Updates a sliver using a new RSPEC.  Only supported in the FULL API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class UpdateSliverCmTask extends ProtogeniXmlrpcTask
	{
		public var aggregateSliver:AggregateSliver;
		public var request:Rspec;
		public var ticket:String;
		
		/**
		 * 
		 * @param newSliver Sliver to update
		 * @param useRspec New RSPEC to update sliver to
		 * 
		 */
		public function UpdateSliverCmTask(newSliver:AggregateSliver,
										   useRspec:Rspec)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_UPDATESLIVER,
				"Update sliver @ " + newSliver.manager.hrn,
				"Updates sliver on " + newSliver.manager.hrn + " for slice named " + newSliver.slice.Name,
				"Update Sliver"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			
			aggregateSliver = newSliver;
			request = useRspec;
			
			addMessage(
				"Waiting to update...",
				"A sliver will be updated at " + aggregateSliver.manager.hrn,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
		
		override protected function createFields():void
		{
			addNamedField("sliver_urn", aggregateSliver.id.full);
			addNamedField("rspec", request.document);
			addNamedField("credentials", [aggregateSliver.slice.credential.Raw]);
		}
		
		override protected function runStart():void
		{
			if(aggregateSliver.manager.api.level == ApiDetails.LEVEL_MINIMAL)
			{
				afterError(
					new TaskError(
						"Full API not supported",
						TaskError.CODE_PROBLEM
					)
				);
				return;
			}
			aggregateSliver.clearStates();
			
			// Generate a rspec if needed
			if(request == null)
			{
				var generateNewRspec:GenerateRequestManifestTask = new GenerateRequestManifestTask(aggregateSliver, true, true, false);
				generateNewRspec.start();
				if(generateNewRspec.Status != Task.STATUS_SUCCESS)
				{
					afterError(generateNewRspec.error);
					return;
				}
				request = generateNewRspec.resultRspec;
				addMessage(
					"Generated request",
					request.document,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
			}
			
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLICE,
				aggregateSliver.slice,
				FlackEvent.ACTION_STATUS
			);
			super.runStart();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				ticket = String(data);
				aggregateSliver.ticket = new Rspec(ticket);
				
				addMessage(
					"Ticket received",
					ticket,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				parent.add(new RedeemTicketCmTask(aggregateSliver));
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}