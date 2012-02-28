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
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.TaskError;
	
	/**
	 * Updates a sliver using a new RSPEC.  Only supported in the FULL API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class UpdateSliverCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var request:Rspec;
		public var ticket:String;
		
		/**
		 * 
		 * @param newSliver Sliver to update
		 * @param useRspec New RSPEC to update sliver to
		 * 
		 */
		public function UpdateSliverCmTask(newSliver:Sliver,
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
			
			sliver = newSliver;
			request = useRspec;
			
			addMessage(
				"Waiting to update...",
				"A sliver will be updated at " + sliver.manager.hrn,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
		
		override protected function createFields():void
		{
			addNamedField("sliver_urn", sliver.id.full);
			addNamedField("rspec", request.document);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function runStart():void
		{
			if(sliver.manager.api.level == ApiDetails.LEVEL_MINIMAL)
			{
				afterError(
					new TaskError(
						"Full API not supported",
						TaskError.CODE_PROBLEM
					)
				);
				return;
			}
			sliver.clearStatus();
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLICE,
				sliver.slice,
				FlackEvent.ACTION_STATUS
			);
			super.runStart();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				ticket = String(data);
				sliver.ticket = ticket;
				
				addMessage(
					"Ticket received",
					ticket,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				parent.add(new RedeemTicketCmTask(sliver));
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}