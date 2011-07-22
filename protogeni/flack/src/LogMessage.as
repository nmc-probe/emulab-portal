/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2011 University of Utah and the Flux Group.
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

package
{
	import protogeni.DateUtil;

	/**
	 * Details about some event which happened
	 * 
	 * @author mstrum
	 * 
	 */
	final public class LogMessage
	{
		public static const TYPE_OTHER:int = 0;
		public static const TYPE_START:int = 1;
		public static const TYPE_END:int = 2;
		
		public static const ERROR_NONE:int = 0;
		public static const ERROR_FAIL:int = 1;
		public static const ERROR_WARNING:int = 2;
		
		/**
		 * Identifier to group, like what CM it's associated with 
		 */
		public var groupId:String;
		
		/**
		 * Human-readable name
		 */
		public var name:String;
		
		/**
		 * Full text
		 */
		public var details:String;
		
		/**
		 * Was this an error?
		 */
		public var errorType:int;
		
		/**
		 * When did this event occur?
		 */
		public var timeStamp:Date;
		
		/**
		 * What kind of log is this?
		 */
		public var type:int;
		
		public function LogMessage(newGroupId:String = "",
								   newName:String = "",
								   newDetails:String = "",
								   newIsError:int = ERROR_NONE,
								   newType:int = 0)
		{
			groupId = newGroupId;
			name = newName;
			details = newDetails;
			errorType = newIsError;
			timeStamp = new Date();
			type = newType;
		}
		
		public function toString():String
		{
			var errorString:String = "";
			if(errorType == ERROR_FAIL)
				errorString = "Error (fail)";
			else if(errorType == ERROR_WARNING)
				errorString = "Error (warning)";
			return "-MSG----------------------------\n" +
				"Flack Version: " + Main.version + "\n" +
				"Name: " + name + "\n" +
				"Group ID: " + groupId + "\n" +
				"Time: " + DateUtil.toRFC3339(timeStamp) + "\n" +
				(errorType != ERROR_NONE ? errorString : "") +
				"\nDetails:\n" + details +
				"\n--------------------------------END-";
		}
	}
}