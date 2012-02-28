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
	 * Collection of tasks
	 * 
	 * @author mstrum
	 * 
	 */
	public final class TaskCollection
	{
		public var collection:Vector.<Task>;
		public function TaskCollection()
		{
			collection = new Vector.<Task>();
		}
		
		public function add(task:Task):void
		{
			collection.push(task);
		}
		
		public function remove(task:Task):int
		{
			var idx:int = collection.indexOf(task);
			if(idx > -1)
				collection.splice(idx, 1);
			return idx;
		}
		
		public function contains(task:Task):Boolean
		{
			return collection.indexOf(task) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @return Same collection as an Array
		 * 
		 */
		public function get AsArray():Array
		{
			var array:Array = [];
			for each(var childTask:Task in collection)
				array.push(childTask);
			return array;
		}
		
		/**
		 * 
		 * @return Combination of all relatedTo values in tasks
		 * 
		 */
		public function get RelatedTo():Array
		{
			var relatedTo:Array = [];
			for each(var childTask:Task in collection)
			{
				for each(var childTaskRelatedTo:* in childTask.relatedTo)
				{
					if(relatedTo.indexOf(childTaskRelatedTo) == -1)
						relatedTo.push(childTaskRelatedTo);
				}
			}
			return relatedTo;
		}
		
		/**
		 * 
		 * @return All tasks including child tasks
		 * 
		 */
		public function get All():TaskCollection
		{
			var allTasks:TaskCollection = new TaskCollection();
			for each(var childTask:Task in collection)
			{
				if(childTask is TaskGroup)
				{
					allTasks.add(childTask);
					var childTasks:TaskCollection = (childTask as TaskGroup).tasks.All;
					for each(var childsTask:* in childTasks.collection)
						allTasks.add(childsTask);
				}
				else
					allTasks.add(childTask);
			}
			return allTasks;
		}
		
		/**
		 * 
		 * @return Inactive tasks
		 * 
		 */
		public function get Inactive():TaskCollection
		{
			return getWithState(Task.STATE_INACTIVE);
		}
		
		/**
		 * 
		 * @return Active tasks
		 * 
		 */
		public function get Active():TaskCollection
		{
			return getWithState(Task.STATE_ACTIVE);
		}
		
		/**
		 * 
		 * @return Tasks which haven't finished
		 * 
		 */
		public function get NotFinished():TaskCollection
		{
			return getOtherThanState(Task.STATE_FINISHED);
		}
		
		/**
		 * 
		 * @return All tasks including descendants which aren't finished 
		 * 
		 */
		public function get AllNotFinished():TaskCollection
		{
			return NotFinished.All.NotFinished;
		}
		
		/**
		 * 
		 * @param state State which the tasks should be in
		 * @return Tasks which are in the given state
		 * 
		 */
		public function getWithState(state:String):TaskCollection
		{
			var newTasks:TaskCollection = new TaskCollection();
			for each(var task:Task in collection)
			{
				if(task.State == state)
					newTasks.add(task);
			}
			return newTasks;
		}
		
		/**
		 * 
		 * @param state State the tasks should not be in
		 * @return Tasks not in the given state
		 * 
		 */
		public function getOtherThanState(state:String):TaskCollection
		{
			var newTasks:TaskCollection = new TaskCollection();
			for each(var task:Task in collection)
			{
				if(task.State != state)
					newTasks.add(task);
			}
			return newTasks;
		}
		
		/**
		 * 
		 * @param type Class of tasks we are looking for
		 * @return Tasks which are of the Class given
		 * 
		 */
		public function getOfClass(type:Class):TaskCollection
		{
			var newTasks:TaskCollection = new TaskCollection();
			for each(var task:Task in collection)
			{
				if(task is type)
					newTasks.add(task);
			}
			return newTasks;
		}
		
		/**
		 * 
		 * @param item Item which tasks should be related to
		 * @return Tasks related to 'item'
		 * 
		 */
		public function getRelatedTo(item:*):TaskCollection
		{
			var newTasks:TaskCollection = new TaskCollection();
			for each(var task:Task in collection)
			{
				if(task.relatedTo.indexOf(item) != -1)
					newTasks.add(task);
			}
			return newTasks;
		}
		
		/**
		 * 
		 * @param items Items which tasks should be related to
		 * @return Tasks related to any items from 'items'
		 * 
		 */
		public function getRelatedToAny(items:Array):TaskCollection
		{
			var newTasks:TaskCollection = new TaskCollection();
			for each(var task:Task in collection)
			{
				for each(var item:* in items)
				{
					if(task.relatedTo.indexOf(item) != -1)
					{
						newTasks.add(task);
						break;
					}
				}
			}
			return newTasks;
		}
	}
}