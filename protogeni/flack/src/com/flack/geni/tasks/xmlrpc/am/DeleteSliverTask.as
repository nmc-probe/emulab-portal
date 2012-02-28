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
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Deallocates all resources in the sliver.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class DeleteSliverTask extends AmXmlrpcTask
	{
		public var sliver:Sliver;
		/**
		 * 
		 * @param deleteSliver Sliver for which to deallocate resources in
		 * 
		 */
		public function DeleteSliverTask(deleteSliver:Sliver)
		{
			super(
				deleteSliver.manager.api.url,
				AmXmlrpcTask.METHOD_DELETESLIVER,
				deleteSliver.manager.api.version,
				"Delete sliver @ " + deleteSliver.manager.hrn,
				"Deleting sliver on aggregate manager " + deleteSliver.manager.hrn + " for slice named " + deleteSliver.slice.Name,
				"Delete Sliver"
			);
			relatedTo.push(deleteSliver);
			relatedTo.push(deleteSliver.slice);
			relatedTo.push(deleteSliver.manager);
			sliver = deleteSliver;
		}
		
		override protected function createFields():void
		{
			addOrderedField(sliver.slice.id.full);
			addOrderedField([sliver.slice.credential.Raw]);
			if(apiVersion > 1)
				addOrderedField({});
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Sanity check for AM API 2+
			if(apiVersion > 1)
			{
				if(genicode != AmXmlrpcTask.GENICODE_SUCCESS && genicode != AmXmlrpcTask.GENICODE_SEARCHFAILED)
				{
					faultOnSuccess();
					return;
				}
			}
			
			try
			{
				if(data == true)
				{
					sliver.manifest = null;
					sliver.removeFromSlice();
					//sliver.UnsubmittedChanges = false;
					
					addMessage(
						"Removed",
						"Slice successfully removed",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLIVER,
						sliver,
						FlackEvent.ACTION_REMOVED
					);
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLICE,
						sliver,
						FlackEvent.ACTION_REMOVING
					);
					
					super.afterComplete(addCompletedMessage);
				}
				else if(data == false)
				{
					afterError(
						new TaskError(
							"Received false when trying to delete sliver on " + sliver.manager.hrn + ".",
							TaskError.CODE_PROBLEM
						)
					);
				}
				else
					throw new Error("Invalid data received");
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