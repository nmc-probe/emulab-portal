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
	 * Registers the given slice at the slice authority.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RegisterSliceSaTask extends ProtogeniXmlrpcTask
	{
		public var slice:Slice;
		
		/**
		 * 
		 * @param newSlice Slice to register
		 * 
		 */
		public function RegisterSliceSaTask(newSlice:Slice)
		{
			super(
				newSlice.authority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_REGISTER,
				"Register " + newSlice.Name,
				"Register slice named " + newSlice.Name,
				"Register Slice"
			);
			relatedTo.push(newSlice);
			
			slice = newSlice;
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
				slice.credential = new GeniCredential(String(data), GeniCredential.TYPE_SLICE, slice.authority);
				slice.expires = slice.credential.Expires;
				
				addMessage(
					"Expires in " + DateUtil.getTimeUntil(slice.expires),
					"Expires in " + DateUtil.getTimeUntil(slice.expires),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Finished",
					"Slice is created and ready to have resources allocated to it.",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				slice.creator.slices.add(slice);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					slice,
					FlackEvent.ACTION_CREATED
				);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					slice,
					FlackEvent.ACTION_NEW
				);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICES,
					slice,
					FlackEvent.ACTION_ADDED
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}