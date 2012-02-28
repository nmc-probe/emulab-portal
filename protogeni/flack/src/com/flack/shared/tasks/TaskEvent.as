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
	import flash.events.Event;
	
	/**
	 * Describes an event for a task
	 * 
	 * @author mstrum
	 * 
	 */
	public class TaskEvent extends Event
	{
		// Events related to the task
		/**
		 * Task has finished in any status (canceled, success, or failed)
		 */
		public static const FINISHED:String = "finished";
		/**
		 * The status has changed (canceled, success, or failed)
		 */
		public static const STATUS:String = "status";
		/**
		 * A log message has been added
		 */
		public static const LOGGED:String = "logged";
		// Events related to child tasks
		/**
		 * A child task has started
		 */
		public static const CHILD_STARTED:String = "child_started";
		/**
		 * A child task was added
		 */
		public static const ADDED:String = "added";
		/**
		 * A child task was removed
		 */
		public static const REMOVED:String = "removed";
		/**
		 * A child task finished in any status (canceled, success, or failed)
		 */
		public static const CHILD_FINISHED:String = "child_finished";
		
		/**
		 * Task which this event is related to
		 */
		public var task:Task;
		
		/**
		 * 
		 * @param type Type of event
		 * @param newTask Task where the event comes from
		 * 
		 */
		public function TaskEvent(type:String,
								  newTask:Task = null)
		{
			super(type);
			task = newTask;
		}
	}
}