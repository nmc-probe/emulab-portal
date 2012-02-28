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
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.utils.ColorUtil;
	import com.flack.shared.utils.NetUtil;
	
	/**
	 * Manager within the GENI world
	 * 
	 * @author mstrum
	 * 
	 */
	public class FlackManager extends IdentifiableObject
	{
		// Denotes the status the manager is in
		public static const STATUS_UNKOWN:int = 0;
		public static const STATUS_INPROGRESS:int = 1;
		public static const STATUS_VALID:int = 2;
		public static const STATUS_FAILED:int = 3;
		
		// What type of manager is this?
		public static const TYPE_PROTOGENI:int = 0;
		public static const TYPE_PLANETLAB:int = 1;
		public static const TYPE_OTHER:int = 2;
		public static const TYPE_OPENFLOW:int = 3;
		public static const TYPE_ORCA:int = 4;
		public static const TYPE_ORBIT:int = 5;
		public static const TYPE_EMULAB:int = 6;
		public static function typeToString(type:int):String
		{
			switch(type)
			{
				case FlackManager.TYPE_PROTOGENI:
					return "ProtoGENI";
				case FlackManager.TYPE_PLANETLAB:
					return "PlanetLab";
				case FlackManager.TYPE_OPENFLOW:
					return "OpenFlow";
				case FlackManager.TYPE_ORCA:
					return "ORCA";
				case FlackManager.TYPE_ORBIT:
					return "ORBIT";
				case FlackManager.TYPE_EMULAB:
					return "Emulab";
				default:
					return "Unknown ("+type+")";
			}
		}
		
		// Why did it fail?
		public static const FAIL_GENERAL:int = 0;
		public static const FAIL_NOTSUPPORTED:int = 1;
		
		// Meta info
		[Bindable]
		public var url:String = "";
		public function get Hostname():String
		{
			return NetUtil.tryGetBaseUrl(url);
		}
		
		[Bindable]
		public var hrn:String = "";
		
		public var type:int;
		
		public var api:ApiDetails;
		public var apis:Vector.<ApiDetails> = new Vector.<ApiDetails>();
		
		// Resources
		public var advertisement:Rspec = null;
		
		// State
		private var status:int = STATUS_UNKOWN;
		public function get Status():int
		{
			return status;
		}
		public function set Status(value:int):void
		{
			if(value == status)
				return;
			status = value;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				this,
				FlackEvent.ACTION_STATUS
			);
		}
		
		public var colorIdx:int = -1;
		
		public var errorType:int = 0;
		[Bindable]
		public var errorMessage:String = "";
		public var errorDescription:String = "";
		
		/**
		 * 
		 * @param newType Type
		 * @param newApi API type
		 * @param newId IDN-URN
		 * @param newHrn Human-readable name
		 * 
		 */
		public function FlackManager(newType:int = TYPE_OTHER,
									newApi:int = 0,
									newId:String = "",
									newHrn:String = "")
		{
			super(newId);
			type = newType;
			api = new ApiDetails(newApi);
			hrn = newHrn;
			
			colorIdx = ColorUtil.getColorIdxFor(id.authority);
		}
		
		/**
		 * 
		 * @return TRUE if it appears the Flash socket security policy isn't installed
		 * 
		 */
		public function mightNeedSecurityException():Boolean
		{
			return errorMessage.search("#2048") > -1;
		}
		
		/**
		 * Clears components, the advertisement, status, and error details
		 * 
		 */
		public function clear():void
		{
			advertisement = null;
			Status = STATUS_UNKOWN;
			errorMessage = "";
			errorDescription = "";
		}
		
		/**
		 * 
		 * @param value Desired client ID
		 * @return Valid client ID usable at this manager
		 * 
		 */
		public function makeValidClientIdFor(value:String):String
		{
			return value;
		}
		
		override public function toString():String
		{
			var result:String = "[FlackManager ID=" + id.full
				+ ", Url=" + url
				+ ", Hrn=" + hrn
				+ ", Type=" + type
				+ ", Api=" + api.type
				+ ", Status=" + Status + "]\n";
			return result += "[/FlackManager]";
		}
	}
}