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

package com.flack.geni.tasks.groups.slice
{
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.am.SliverStatusTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.SliverStatusCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Refresh the status of the slice, slivers and all resources
	 * @author mstrum
	 * 
	 */
	public final class RefreshSliceStatusTaskGroup extends ParallelTaskGroup
	{
		public var slice:Slice;
		public var continueUntilDone:Boolean;
		
		/**
		 * 
		 * @param newSlice Slice to refresh the status for
		 * @param shouldContinueUntilDone Continue running until all statuses are finalized?
		 * 
		 */
		public function RefreshSliceStatusTaskGroup(newSlice:Slice,
													shouldContinueUntilDone:Boolean = true)
		{
			super(
				"Refresh status for " + newSlice.Name,
				"Refreshes status for all slivers on " + newSlice.Name
			);
			relatedTo.push(newSlice);
			slice = newSlice;
			continueUntilDone = shouldContinueUntilDone;
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
			{
				slice.clearStatus();
				for each(var addedSliver:Sliver in slice.slivers.collection)
				{
					if(addedSliver.manager.api.type == ApiDetails.API_GENIAM)
						add(new SliverStatusTask(addedSliver, continueUntilDone));
					else
						add(new SliverStatusCmTask(addedSliver, continueUntilDone));
				}
			}
			super.runStart();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			addMessage(
				StringUtil.firstToUpper(slice.Status),
				"Sliver statuses have been reported to be " + slice.Status,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			
			super.afterComplete(addCompletedMessage);
		}
	}
}