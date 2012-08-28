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
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * Dispatches events to any listener for GENI-related events
	 * 
	 * @author mstrum
	 * 
	 */
	public final class FlackDispatcher extends EventDispatcher
	{
		public function FlackDispatcher(target:IEventDispatcher = null)
		{
			super(target);
		}
		
		public function dispatchChanged(changed:String,
										obj:Object,
										action:int = 0):void
		{
			dispatchEvent(
				new FlackEvent(
					changed,
					obj,
					action
				)
			);
		}
	}
}