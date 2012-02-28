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

package com.flack.shared
{
	import flash.events.Event;
	
	/**
	 * Event within our world
	 * 
	 * @author mstrum
	 * 
	 */
	public final class FlackEvent extends Event
	{
		// Actions
		public static const ACTION_CREATED:int = 0;
		public static const ACTION_STATUS:int = 1;
		public static const ACTION_CHANGED:int = 2;
		public static const ACTION_POPULATING:int = 3;
		public static const ACTION_POPULATED:int = 4;
		public static const ACTION_REMOVING:int = 5;
		public static const ACTION_REMOVED:int = 6;
		public static const ACTION_ADDED:int = 7;
		public static const ACTION_SELECTED:int = 9;
		public static const ACTION_NEW:int = 10;
		
		// Types of objects which change and get events thrown for
		public static const CHANGED_MANAGERS:String = "managers_changed";
		public static const CHANGED_MANAGER:String = "manager_changed";
		public static const CHANGED_USER:String = "user_changed";
		public static const CHANGED_TASK:String = "task_changed";
		public static const CHANGED_LOG:String = "log_changed";
		public static const CHANGED_UNIVERSE:String = "universe_changed";
		// GENI
		public static const CHANGED_SLICES:String = "slices_changed";
		public static const CHANGED_SLICE:String = "slice_changed";
		public static const CHANGED_SLIVER:String = "sliver_changed";
		public static const CHANGED_AUTHORITIES:String = "authorities_changed";
		// Emulab
		public static const CHANGED_EXPERIMENTS:String = "experiments_changed";
		public static const CHANGED_EXPERIMENT:String = "experiment_changed";
		
		/**
		 * Object which has changed
		 */
		public var changedObject:Object = null;
		/**
		 * Action taken on the changedObject
		 */
		public var action:int;
		
		/**
		 * 
		 * @param newType Type of event
		 * @param newChangedObject Object which the event is about
		 * @param newAction Action the object has taken
		 * 
		 */
		public function FlackEvent(newType:String,
								  newChangedObject:Object = null,
								  newAction:int = 0)
		{
			super(newType);
			changedObject = newChangedObject;
			action = newAction;
		}
		
		override public function clone():Event
		{
			return new FlackEvent(type, changedObject, action);
		}
	}
}