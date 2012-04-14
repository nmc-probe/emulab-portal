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
	import com.flack.geni.tasks.process.GenerateRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	
	import mx.controls.Alert;
	
	/**
	 * Updates a sliver using a new RSPEC.  Only supported in the FULL API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetTicketCmTask extends ProtogeniXmlrpcTask
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
		public function GetTicketCmTask(newSliver:Sliver,
										useRspec:Rspec = null)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_GETTICKET,
				"Get ticket @ " + newSliver.manager.hrn,
				"Get ticket on " + newSliver.manager.hrn + " for slice named " + newSliver.slice.Name,
				"Get ticket"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			
			sliver = newSliver;
			request = useRspec;
			
			addMessage(
				"Waiting to get ticket...",
				"A ticket will be ask for at " + sliver.manager.hrn,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sliver.slice.id.full);
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
			
			if(request == null)
			{
				var generateNewRspec:GenerateRequestManifestTask = new GenerateRequestManifestTask(sliver, true, false, false);
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
			{
				if(output.indexOf("must release") != -1)
					Alert.show("Ticket must expire before trying again");
				faultOnSuccess();
			}
		}
	}
}