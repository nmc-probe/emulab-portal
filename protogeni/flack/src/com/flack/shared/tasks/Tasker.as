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

package com.flack.shared.tasks
{
	import com.flack.shared.utils.ArrayUtil;

	/**
	 * Manages all tasks/task groups, generally only one instance is needed
	 * 
	 * @author mstrum
	 * 
	 */
	public class Tasker extends ParallelTaskGroup
	{
		public function Tasker()
		{
			super(
				"Tasker",
				"Handles all tasks, running tasks in parallel if they don't have overlapping dependencies"
			);
			State = Task.STATE_ACTIVE;
		}
		
		/**
		 * Follows the following:
		 * If inactive, don't start anything new
		 * If running a task which uses forceSerial, wait to start the next task until it has finished
		 * Otherwise start any tasks until the parallel running limit is hit, but skip tasks which depend on active tasks
		 * 
		 */
		override protected function runStart():void
		{
			// Not started yet
			if(State == Task.STATE_INACTIVE)
				return;
			// Running a serial task
			var running:TaskCollection = tasks.Active;
			var runningRelatedTo:Array = running.All.RelatedTo;
			if(running.length > 0 && running.collection[0].forceSerial)
				return;
			
			var inactiveTasks:TaskCollection = tasks.Inactive;
			for each(var task:Task in inactiveTasks.collection)
			{
				// Already at the limit, don't start any more
				if(Running >= limitRunningCount)
					return;
				// Don't run if potential new task has dependencies (is related) to a task running
				if(ArrayUtil.overlap(runningRelatedTo, task.relatedTo))
					continue;
				if(!task.forceSerial || Running == 0)
				{
					task.start();
					if(task.forceSerial)
					{
						completeIfFinished(false);
						return;
					}
				}
			}
			completeIfFinished(false);
		}
		
		override protected function removeHandlers():void
		{
			// don't remove the handlers, they should always exist
		}
	}
}