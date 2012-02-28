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
	/**
	 * Completes added tasks one after the other.
	 * 
	 * Default behavior when a child...
	 * 
	 * Errors: Cancel remaining and reports error unless skipErrors is TRUE
	 * Canceled: Continues running others
	 * 
	 * @author mstrum
	 * 
	 */
	public class SerialTaskGroup extends TaskGroup
	{
		protected var index:int = -1;
		protected var skipErrors:Boolean;
		protected var skipCancels:Boolean;
		
		/**
		 * 
		 * @param taskFullName Name of the task, including contextual queues
		 * @param taskDescription Description of what the task does
		 * @param taskShortName Shortest name of the task understandable in context
		 * @param taskParent Parent to assign the task to
		 * @param taskSkipErrors Skip errors instead of erroring entire group?
		 * @param taskSkipCancels Skip cancels instead of canceling entire group?
		 * 
		 */
		public function SerialTaskGroup(taskFullName:String = "Serial tasks",
										taskDescription:String = "Runs tasks one after the other",
										taskShortName:String = "",
										taskParent:TaskGroup = null,
										taskSkipErrors:Boolean = false,
										taskSkipCancels:Boolean = true)
		{
			super(
				taskFullName,
				taskDescription,
				taskShortName,
				taskParent
			);
			skipErrors = taskSkipErrors;
			skipCancels = taskSkipCancels;
		}
		
		/**
		 * If active, starts the next child task if previosu task completed or signals completion of all tasks.
		 * 
		 */
		override protected function runStart():void
		{
			// Not started yet
			if(State == Task.STATE_INACTIVE)
				return;
			// Finished with no tasks added
			if(index > tasks.length-1)
				return;
			
			// Set index to the task that needs to be running
			if(index == -1)
				index = 0;
			while(index < tasks.length && tasks.collection[index].State == Task.STATE_FINISHED)
				index++;
			
			// All finished
			if(index > tasks.length-1)
			{
				if(State == Task.STATE_ACTIVE)
				{
					Status = Task.STATUS_SUCCESS;
					afterComplete();
				}
				return;
			}
			// Still some stuff to do even if we were finished
			else if(State == Task.STATE_FINISHED)
			{
				State = Task.STATE_ACTIVE;
				Status = Task.STATUS_RUNNING;
			}
			
			// Run the current task if it's inactive
			if(State == Task.STATE_ACTIVE && tasks.collection[index].State == Task.STATE_INACTIVE)
			{
				tasks.collection[index].start();
			}
		}
		
		/**
		 * Starts running the child task if needed, otherwise continues running current
		 * 
		 * @param task Child task which was added
		 * 
		 */
		override protected function addedTask(task:Task):void
		{
			if(task.forceRunNow)
				task.start();
			
			runStart();
		}
		
		/**
		 * Continues running other child tasks
		 * 
		 * @param task Child task which was removed
		 * @param idx Index of the task
		 * 
		 */
		override public function removedTask(task:Task, idx:int):void
		{
			// Removed completed task
			if(idx < index)
				index--;
			// Removed current task
			else if(idx == index)
				runStart();
		}
		
		/**
		 * Continues running other tasks
		 * 
		 * @param task Child task which was canceled
		 * 
		 */
		override public function canceledTask(task:Task):void
		{
			super.canceledTask(task);
			if(skipCancels)
				runStart();
			else
			{
				// XXX afterError??
				cancelRemainingTasks();
			}
		}
		
		/**
		 * Child task is done, move to the next
		 * 
		 * @param task Child task which was completed
		 * 
		 */
		override public function completedTask(task:Task):void
		{
			super.completedTask(task);
			runStart();
		}
		
		/**
		 * Cancels all remaining child tasks and reports error
		 * 
		 * @param task Child task which errored
		 * 
		 */
		override public function erroredTask(task:Task):void
		{
			super.erroredTask(task);
			if(skipErrors)
				runStart();
			else
			{
				afterError(task.error);
				cancelRemainingTasks();
			}
		}
	}
}