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
	
	/**
	 * Gets the slice credential for access to the slice.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetSliceCredentialSaTask extends ProtogeniXmlrpcTask
	{
		public var slice:Slice;
		
		/**
		 * 
		 * @param taskSlice Slice for which we are getting the credential for
		 * 
		 */
		public function GetSliceCredentialSaTask(taskSlice:Slice)
		{
			super(
				taskSlice.authority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_GETCREDENTIAL,
				"Get slice credential for " + taskSlice.Name,
				"Getting the slice credential for " + taskSlice.Name,
				"Get slice credential"
			);
			relatedTo.push(taskSlice);
			slice = taskSlice;
		}
		
		override protected function createFields():void
		{
			addNamedField("credential", slice.authority.userCredential.Raw);
			addNamedField("urn", slice.id.full);
			addNamedField("type", "Slice");
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				slice.credential = new GeniCredential(data, GeniCredential.TYPE_SLICE, slice.authority);
				slice.expires = slice.credential.Expires;
				
				addMessage(
					"Expires in " + DateUtil.getTimeUntil(slice.expires),
					"Expires in " + DateUtil.getTimeUntil(slice.expires),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Received",
					"Credential retreived for slice.",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					slice
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}