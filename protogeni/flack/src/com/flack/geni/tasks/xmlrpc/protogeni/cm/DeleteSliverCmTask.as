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
	
	/**
	 * Releases all resources allocated to the sliver.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class DeleteSliverCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		
		/**
		 * 
		 * @param deleteSliver Sliver to deallocate resources for
		 * 
		 */
		public function DeleteSliverCmTask(deleteSliver:Sliver)
		{
			super(
				deleteSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_DELETESLICE,
				"Delete sliver @ " + deleteSliver.manager.hrn,
				"Deleting sliver on component manager " + deleteSliver.manager.hrn + " for slice named " + deleteSliver.slice.Name,
				"Delete Sliver"
			);
			relatedTo.push(deleteSliver);
			relatedTo.push(deleteSliver.slice);
			relatedTo.push(deleteSliver.manager);
			sliver = deleteSliver;
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sliver.slice.id.full);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(code == ProtogeniXmlrpcTask.CODE_SUCCESS
				|| code == ProtogeniXmlrpcTask.CODE_SEARCHFAILED)
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
					sliver.slice,
					FlackEvent.ACTION_REMOVING
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}