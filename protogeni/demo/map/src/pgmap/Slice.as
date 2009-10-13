/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2009 University of Utah and the Flux Group.
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
 
 package pgmap
{
	import mx.collections.ArrayCollection;
	
	public class Slice
	{
		public var uuid : String = null;
		public var hrn : String = null;
		public var creator : User = null;
		public var credential : String = null;
		public var sliverCredential : String = null;
		
		public var status : String = null;
		public var sliverStatus : String = null;
		
		public var Nodes : ArrayCollection = new ArrayCollection();
		public var Links : ArrayCollection = new ArrayCollection();
		
		public function Slice()
		{
		}
		
		public function ReadyIcon():Class {
			switch(status) {
				case "ready" : return Common.flagGreenIcon;
				case "notready" : return Common.flagYellowIcon;
				case "failed" : return Common.flagRedIcon;
				default : return null;
			}
		}
		
		public function DisplayString():String {
			
			if(hrn == null && uuid == null) {
				return "All Resources";
			}
			
			var returnString : String;
			if(hrn == null)
				returnString = uuid;
			else
				returnString = hrn;
				
			switch(status) {
				case "ready":
					switch(sliverStatus) {
						case "ready": hrn += " (All Ready)";
						case "notready": hrn += " (Sliver Not Ready)";
						case "failed": hrn += " (Sliver Failed)";
						default: hrn += " (Unknown Sliver Status)";
					}
					break;
				case "notready": hrn += " (Not Ready)";
				case "failed": hrn += " (Unknown)";
				default: hrn += " (Unknown)";
			}
			return returnString;
		}
	}
}