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
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.StopSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.TaskError;
	
	import mx.controls.Alert;
	
	/**
	 * Stops all of the slivers in the slice
	 * 
	 * @author mstrum
	 * 
	 */
	public final class StopSliceTaskGroup extends SerialTaskGroup
	{
		public var slice:Slice;
		
		/**
		 * 
		 * @param newSlice Slice to stop all the slivers in
		 * 
		 */
		public function StopSliceTaskGroup(newSlice:Slice)
		{
			super(
				"Stop " + newSlice.Name,
				"Stops all reasources in " + newSlice.Name
			);
			slice = newSlice;
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
			{
				var runTasks:ParallelTaskGroup = new ParallelTaskGroup("Stop all", "Stops all the slivers");
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					if(sliver.manager.api.type == ApiDetails.API_PROTOGENI)
					{
						if(sliver.manager.api.level == ApiDetails.LEVEL_FULL)
							runTasks.add(new StopSliverCmTask(sliver));
						else
						{
							var msg:String = sliver.manager.hrn + "doesn't support the full API so it cannot be stopped.";
							addMessage(
								"Sliver not stopped",
								msg,
								LogMessage.LEVEL_FAIL,
								LogMessage.IMPORTANCE_HIGH
							);
							Alert.show(msg, "Sliver not stopped");
						}
					}
				}
				add(runTasks);
				add(new RefreshSliceStatusTaskGroup(slice));
			}
			super.runStart();
		}
		
		// Sanity check
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(slice.Status != Sliver.STATUS_STOPPED)
			{
				addMessage("Failed to stop", "All slivers don't report stopped");
				afterError(
					new TaskError(
						"Slivers failed to stop",
						TaskError.CODE_UNEXPECTED
					)
				);
			}
			else
			{
				addMessage("Stopped", "All slivers report stopped", LogMessage.LEVEL_INFO, LogMessage.IMPORTANCE_HIGH);
				super.afterComplete(addCompletedMessage);
			}
		}
	}
}