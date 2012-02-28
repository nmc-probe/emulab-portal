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

package com.flack.geni.tasks.xmlrpc.protogeni.sa
{
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.utils.DateUtil;
	
	import mx.controls.Alert;
	
	/**
	 * Renews a slice, NOT INCLUDING SLIVERS, until the given date.
	 */
	public final class RenewSliceSaTask extends ProtogeniXmlrpcTask
	{
		public var slice:Slice;
		public var newExpires:Date;
		
		/**
		 * 
		 * @param renewSlice Slice to renew
		 * @param newExpirationDate Desired expiration date/time
		 * 
		 */
		public function RenewSliceSaTask(renewSlice:Slice,
										 newExpirationDate:Date)
		{
			super(
				renewSlice.creator.authority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_RENEWSLICE,
				"Renew " + renewSlice.Name,
				"Renewing slice named " + renewSlice.Name,
				"Renew Slice"
			);
			relatedTo.push(renewSlice);
			slice = renewSlice;
			newExpires = newExpirationDate;
			
			addMessage(
				"Details",
				"Adding " +DateUtil.getTimeBetween(slice.expires, newExpires)+ " for a total of "+DateUtil.getTimeUntil(newExpires)+" until expiration",
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
		
		override protected function createFields():void
		{
			addNamedField("credential", slice.credential.Raw);
			addNamedField("expiration", DateUtil.toRFC3339(newExpires));
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				slice.credential = new GeniCredential(String(data), GeniCredential.TYPE_SLICE, slice.creator.authority);
				slice.expires = slice.credential.Expires;
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					slice
				);
				
				addMessage(
					"Renewed",
					"Renewed, expires in " + DateUtil.getTimeUntil(slice.expires),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
			{
				Alert.show("Failed to renew slice " + slice.Name);
				faultOnSuccess();
			}
				
		}
	}
}