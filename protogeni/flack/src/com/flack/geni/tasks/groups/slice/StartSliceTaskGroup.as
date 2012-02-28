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
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.StartSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.TaskError;
	
	/**
	 * Starts all of the resources in a slice
	 * 
	 * @author mstrum
	 * 
	 */
	public final class StartSliceTaskGroup extends SerialTaskGroup
	{
		public var slice:Slice;
		
		/**
		 * 
		 * @param newSlice Slice to start all resources in
		 * 
		 */
		public function StartSliceTaskGroup(newSlice:Slice)
		{
			super(
				"Start " + newSlice.Name,
				"Starts all reasources in " + newSlice.Name
			);
			relatedTo.push(newSlice);
			slice = newSlice;
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
			{
				var runTasks:ParallelTaskGroup = new ParallelTaskGroup("Start all", "Starts all the slivers");
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					if(sliver.manager.api.type == ApiDetails.API_PROTOGENI)
					{
						if(sliver.manager.api.level == ApiDetails.LEVEL_FULL)
							runTasks.add(new StartSliverCmTask(sliver));
						else // XXX this either needs to be optional or perhaps ask the user?
							runTasks.add(new RestartSliverCmTask(sliver));
					}
					else
						addMessage(
							"Can't start @ " + sliver.manager.hrn,
							"The manager " + sliver.manager.hrn + " doesn't support the start task",
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH);
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
				addMessage("Failed to start", "All slivers don't report ready");
				afterError(
					new TaskError(
						"Slivers failed to start",
						TaskError.CODE_UNEXPECTED
					)
				);
			}
			else
			{
				addMessage("Started", "All slivers report ready");
				super.afterComplete(addCompletedMessage);
			}
		}
	}
}