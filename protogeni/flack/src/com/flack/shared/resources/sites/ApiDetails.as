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

package com.flack.shared.resources.sites
{
	/**
	 * Details related to the API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class ApiDetails
	{
		// What interface is used?
		public static const API_GENIAM:int = 0;
		public static const API_PROTOGENI:int = 1;
		public static const API_SFA:int = 2;
		public static const API_EMULAB:int = 3;
		
		// ProtoGENI levels
		public static const LEVEL_MINIMAL:int = 0;
		public static const LEVEL_FULL:int = 1;
		
		public var type:int;
		public var version:Number;
		public var url:String;
		public var level:int;
		
		/**
		 * 
		 * @param newType Type
		 * @param newVersion Version
		 * @param newUrl URL
		 * @param newLevel Level
		 * 
		 */
		public function ApiDetails(newType:int = -1,
								   newVersion:Number = NaN,
								   newUrl:String = "",
								   newLevel:int = 0)
		{
			type = newType;
			version = newVersion;
			url = newUrl;
			level = newLevel;
		}
		
		public function toString():String
		{
			var result:String = "";
			switch(type)
			{
				case ApiDetails.API_GENIAM:
					result = "GENI AM";
					break;
				case ApiDetails.API_PROTOGENI:
					result = "ProtoGENI";
					if(level == ApiDetails.LEVEL_FULL)
						result += " (full)";
					else
						result += " (minimal)";
					break;
				case ApiDetails.API_SFA:
					result = "SFA";
					break;
				case ApiDetails.API_EMULAB:
					result = "Emulab";
					break;
				default:
					result = "Unknown";
			}
			
			if(version)
				result += " v" + version;
			
			return result;
		}
	}
}