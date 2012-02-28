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
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.RestartSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.TaskError;
	
	/**
	 * Restarts all of the resources in a slice
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RestartSliceTaskGroup extends SerialTaskGroup
	{
		public var slice:Slice;
		
		/**
		 * 
		 * @param newSlice Slice to restart all resources in
		 * 
		 */
		public function RestartSliceTaskGroup(newSlice:Slice)
		{
			super(
				"Restart " + newSlice.Name,
				"Restarts all reasources in " + newSlice.Name
			);
			relatedTo.push(newSlice);
			slice = newSlice;
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
			{
				var runTasks:ParallelTaskGroup = new ParallelTaskGroup("Restart all", "Restarts all the slivers");
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					if(sliver.manager.api.type == ApiDetails.API_PROTOGENI)
						runTasks.add(new RestartSliverCmTask(sliver));
				}
				add(runTasks);
				add(new RefreshSliceStatusTaskGroup(slice));
			}
			super.runStart();
		}
		
		// Sanity check
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(slice.Status != Sliver.STATUS_READY)
			{
				addMessage("Failed to restart", "All slivers don't report ready");
				afterError(
					new TaskError(
						"Slivers failed to restart",
						TaskError.CODE_UNEXPECTED
					)
				);
			}
			else
			{
				addMessage(
					"Restarted",
					"All slivers report ready",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				super.afterComplete(addCompletedMessage);
			}
		}
	}
}