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
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	
	/**
	 * Ensures that a slice has been removed. Only works when the slice has expired.
	 * If no slice with the same name exists or if it is removed, the register task is added to the parent task.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RemoveSliceSaTask extends ProtogeniXmlrpcTask
	{
		public var slice:Slice;
		
		/**
		 * 
		 * @param newSlice Slice to remove
		 * 
		 */
		public function RemoveSliceSaTask(newSlice:Slice)
		{
			super(
				newSlice.authority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_REMOVE,
				"Remove " + newSlice.Name,
				"Remove slice named " + newSlice.Name,
				"Remove Slice"
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
		
		override protected function afterComplete(addCompletedMessage:Boolean=true):void
		{
			if (
				code == ProtogeniXmlrpcTask.CODE_SUCCESS ||
				code == ProtogeniXmlrpcTask.CODE_SEARCHFAILED
			)
			{
				parent.add(new RegisterSliceSaTask(slice));
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}