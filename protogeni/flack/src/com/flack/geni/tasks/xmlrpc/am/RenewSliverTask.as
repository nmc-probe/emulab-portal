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
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.DateUtil;
	import com.flack.shared.utils.StringUtil;
	
	import mx.controls.Alert;
	
	/**
	 * Renews the sliver until the given date.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RenewSliverTask extends AmXmlrpcTask
	{
		public var sliver:Sliver;
		public var newExpires:Date;
		
		/**
		 * 
		 * @param renewSliver Sliver to renew
		 * @param newExpirationDate Desired expiration date
		 * 
		 */
		public function RenewSliverTask(renewSliver:Sliver,
										newExpirationDate:Date)
		{
			super(
				renewSliver.manager.api.url,
				AmXmlrpcTask.METHOD_RENEWSLIVER,
				renewSliver.manager.api.version,
				"Renew sliver @ " + renewSliver.manager.hrn,
				"Renewing sliver on " + renewSliver.manager.hrn + " on slice named " + renewSliver.slice.hrn,
				"Renew Sliver"
			);
			relatedTo.push(renewSliver);
			relatedTo.push(renewSliver.slice);
			relatedTo.push(renewSliver.manager);
			sliver = renewSliver;
			newExpires = newExpirationDate;
		}
		
		override protected function createFields():void
		{
			addOrderedField(sliver.slice.id.full);
			addOrderedField([sliver.slice.credential.Raw]);
			addOrderedField(DateUtil.toRFC3339(newExpires));
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
				if(data == true)
				{
					sliver.expires = newExpires;
					
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLIVER,
						sliver
					);
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLICE,
						sliver.slice
					);
					
					addMessage(
						"Renewed",
						"Renewed, sliver expires in " + DateUtil.getTimeUntil(sliver.expires),
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					super.afterComplete(addCompletedMessage);
				}
				else if(data == false)
				{
					Alert.show("Failed to renew sliver @ " + sliver.manager.hrn);
					afterError(
						new TaskError(
							"Renew failed",
							TaskError.CODE_PROBLEM
						)
					);
				}
				else
				{
					afterError(
						new TaskError(
							"Renew failed. Received incorrect data",
							TaskError.CODE_UNEXPECTED
						)
					);
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