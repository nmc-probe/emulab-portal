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
	
	import mx.controls.Alert;
	
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
				"Redeem ticket @ " + newSliver.manager.hrn,
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
			if(sliver.credential != null && sliver.credential.Raw.length > 0)
				addNamedField("credentials", [sliver.credential.Raw]);
			else
				addNamedField("credentials", [sliver.slice.credential.Raw]);
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
				sliver.id = sliver.credential.TargetId;
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
				
				parent.add(new ParseRequestManifestTask(sliver, sliver.manifest, false, true));
				parent.add(new StartSliverCmTask(sliver));
			}
			else
			{
				addMessage(
					"Problem redeeming",
					"There was a problem redeeming the ticket. The ticket will now be released.",
					LogMessage.LEVEL_FAIL,
					LogMessage.IMPORTANCE_HIGH
				);
				Alert.show("Problem redeeming ticket at " + sliver.manager.hrn);
				
				// Release the ticket so the user can get another
				parent.add(new ReleaseTicketCmTask(sliver));
				// Re-get the sliver to represent how it currently is
				parent.add(new GetSliverCmTask(sliver));
			}
				
			super.afterComplete(addCompletedMessage);
		}
	}
}