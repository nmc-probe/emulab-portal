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

package com.flack.geni.resources.virtual.extensions
{
	import com.flack.shared.SharedMain;
	
	import flash.system.Capabilities;
	
	import mx.core.FlexGlobals;

	/**
	 * Client Info extension
	 * 
	 * @author mstrum
	 * 
	 */
	public class ClientInfo
	{
		public var name:String;	
		
		/**
		 * Flash, OS, Arch, etc.
		 */
		public var environment:String;
		
		public var version:String;
		
		public var url:String;
		
		public function ClientInfo()
		{
			name = "Flack";
			version = SharedMain.version;
			environment = "Flash Version: " + Capabilities.version + ", OS: " + Capabilities.os + ", Arch: " + Capabilities.cpuArchitecture + ", Screen: " + Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY+" @ "+Capabilities.screenDPI+" DPI with touchscreen type "+Capabilities.touchscreenType;
			url = FlexGlobals.topLevelApplication.url;
		}
		
		public function toString():String
		{
			return "Client Name: " + name + "\nClient Version: "+ version + "\nClient Environment: "+environment + "\nClient URL: " + url;
		}
	}
}