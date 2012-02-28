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
	 * Details about an error that occured in a task
	 * 
	 * @author mstrum
	 * 
	 */
	public class TaskError extends Error
	{
		/**
		 * Task timed out
		 */
		public static const TIMEOUT:uint = 0;
		/**
		 * Unexpected problem while executing code, like null pointers
		 */
		public static const CODE_UNEXPECTED:uint = 1;
		/**
		 * Error found while executing in code, like an incorrect format detected
		 */
		public static const CODE_PROBLEM:uint = 2;
		/**
		 * Error outside of the scope of the running code, like an error from JavaScript
		 */
		public static const FAULT:uint = 3;
		
		/**
		 * Data relevant to the error
		 */
		public var data:*;
		
		/**
		 * 
		 * @param message Message of the error
		 * @param id Error number
		 * @param errorData Data related to the error
		 * 
		 */
		public function TaskError(message:String = "",
								  id:uint = 0,
								  errorData:* = null)
		{
			super(message, id);
			data = errorData;
		}
		
		public function toString():String
		{
			return "[TaskError ID="+errorID+" Message=\""+message+"\", ]";
		}
	}
}