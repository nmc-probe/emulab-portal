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

package com.flack.shared.logging
{
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	
	import flash.events.EventDispatcher;

	/**
	 * Top level handler for log messages throughout the geni library
	 * 
	 * @author mstrum
	 * 
	 */
	public class Logger extends EventDispatcher
	{
		private var _logs:LogMessageCollection;
		public function get Logs():LogMessageCollection
		{
			return _logs;
		}
		
		public function Logger()
		{
			_logs = new LogMessageCollection();
		}
		
		/**
		 * Adds the message and dispatches an event
		 * 
		 * @param msg Message to add
		 * 
		 */
		public function add(msg:LogMessage):void
		{
			_logs.add(msg);
			dispatchEvent(new FlackEvent(FlackEvent.CHANGED_LOG, msg, FlackEvent.ACTION_CREATED));
		}
		
		/**
		 * Dispatches a selected event for the owner.  Kind of dirty, but not used very much.
		 * 
		 * @param owner null or tasker indicates all messages, otherwise owner is selected
		 * 
		 */
		public function view(owner:*):void
		{
			if(owner == SharedMain.tasker)
				dispatchEvent(new FlackEvent(FlackEvent.CHANGED_LOG, null, FlackEvent.ACTION_SELECTED));
			else
				dispatchEvent(new FlackEvent(FlackEvent.CHANGED_LOG, owner, FlackEvent.ACTION_SELECTED));
		}
	}
}