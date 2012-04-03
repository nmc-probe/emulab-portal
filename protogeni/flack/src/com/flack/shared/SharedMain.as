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
	import com.flack.emulab.EmulabMain;
	import com.flack.geni.GeniMain;
	import com.flack.shared.logging.Logger;
	import com.flack.shared.resources.FlackUser;
	import com.flack.shared.tasks.Tasker;
	import com.mattism.http.xmlrpc.JSLoader;
	
	import flash.system.Capabilities;
	
	import mx.core.FlexGlobals;
	
	/**
	 * Global container for things we use
	 * 
	 * @author mstrum
	 * 
	 */
	public class SharedMain
	{
		/**
		 * Flack version
		 */
		public static const version:String = "v14.6";
		
		public static const MODE_GENI:int = 0;
		public static const MODE_EMULAB:int = 1;
		
		public static var mode:int = MODE_GENI;
		public static function preinitMode():void
		{
			switch(mode)
			{
				case MODE_EMULAB:
					EmulabMain.preinitMode();
					break;
				default:
					GeniMain.preinitMode();
			}
		}
		public static function initMode():void
		{
			switch(mode)
			{
				case MODE_EMULAB:
					EmulabMain.initMode();
					break;
				default:
					GeniMain.initMode();
			}
			
		}
		public static function loadParams():void
		{
			switch(mode)
			{
				case MODE_EMULAB:
					EmulabMain.loadParams();
					break;
				default:
					GeniMain.loadParams();
			}
		}
		
		public static function initPlugins():void
		{
			switch(mode)
			{
				case MODE_EMULAB:
					EmulabMain.initPlugins();
					break;
				default:
					GeniMain.initPlugins();
			}
		}
		
		public static function runFirst():void
		{
			switch(mode)
			{
				case MODE_EMULAB:
					EmulabMain.runFirst();
					break;
				default:
					GeniMain.runFirst();
			}
		}
		
		/**
		 * Dispatches all geni events
		 */
		public static var sharedDispatcher:FlackDispatcher = new FlackDispatcher();
		
		/**
		 * All logs of what has happened in Flack
		 */
		public static var logger:Logger = new Logger();
		
		public static var tasker:Tasker = new Tasker();
		
		[Bindable]
		public static var user:FlackUser;
		
		[Bindable]
		private static var bundle:String = "";
		/**
		 * Sets the SSL Cert bundle here and in Forge
		 * 
		 * @param value New SSL Cert bundle to use
		 * 
		 */
		public static function set Bundle(value:String):void
		{
			bundle = value;
			SharedCache.updateCertBundle(value);
			JSLoader.setServerCertificate(value);
		}
		/**
		 * 
		 * @return SSL Cert bundle being used
		 * 
		 */
		[Bindable]
		public static function get Bundle():String
		{
			return bundle;
		}
		
		public static function get ClientString():String
		{
			return "Client: Flack\n"
				+"Version: "+ version + "\n"
				+"Flash Version: " + Capabilities.version + ", OS: " + Capabilities.os + ", Arch: " + Capabilities.cpuArchitecture + ", Screen: " + Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY+" @ "+Capabilities.screenDPI+" DPI with touchscreen type "+Capabilities.touchscreenType + "\n"
				+"URL: " + FlexGlobals.topLevelApplication.url;
		}
	}
}
