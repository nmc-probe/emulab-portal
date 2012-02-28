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
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.DateUtil;
	
	/**
	 * Redeems an issued ticket. Only supported on the FULL API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RedeemTicketCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		// hack, afterError should probably be called instead of setting this
		public var success:Boolean = false;
		
		/**
		 * 
		 * @param newSliver Sliver to redeem ticket for
		 * 
		 */
		public function RedeemTicketCmTask(newSliver:Sliver)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_REDEEMTICKET,
				"ProtogeniXmlrpcTask ticket @ " + newSliver.manager.hrn,
				"Updates ticket for sliver on " + newSliver.manager.hrn + " for slice named " + newSliver.slice.Name,
				"Redeem Ticket"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			sliver = newSliver;
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
			
			sliver.markStaged();
			sliver.manifest = null;
			
			super.runStart();
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sliver.slice.id.full);
			addNamedField("credentials", [sliver.credential.Raw]);
			addNamedField("ticket", sliver.ticket);
			var keys:Array = [];
			for each(var key:String in sliver.slice.creator.keys) {
				keys.push({type:"ssh", key:key});
			}
			addNamedField("keys", keys);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				success = true;
				sliver.credential = new GeniCredential(data[0], GeniCredential.TYPE_SLIVER, sliver.manager);
				sliver.expires = sliver.credential.Expires;
				sliver.manifest = new Rspec(data[1], null, null, null, Rspec.TYPE_MANIFEST);
				
				addMessage(
					"Credential received",
					data[0],
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Manifest received",
					data[1],
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Expires in " + DateUtil.getTimeUntil(sliver.expires),
					"Expires in " + DateUtil.getTimeUntil(sliver.expires),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				parent.add(new ParseRequestManifestTask(sliver, sliver.manifest));
				parent.add(new StartSliverCmTask(sliver));
			}
			else
			{
				addMessage(
					"Problem redeeming",
					"There was a problem redeeming the ticket. The ticket will now be released.",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				parent.add(new ReleaseTicketCmTask(sliver));
			}
				
			super.afterComplete(addCompletedMessage);
		}
	}
}