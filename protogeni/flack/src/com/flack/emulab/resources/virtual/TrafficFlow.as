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

package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.NamedObject;
	
	public class TrafficFlow extends NamedObject
	{
		static public const TYPE_UDP:String = "UDP";
		static public const TYPE_TCP:String = "TCP";
		
		public var generators:TrafficGeneratorCollection = null;
		public var sinks:VirtualInterface;
		public var bidirectional:Boolean = false;
		public var rate:Number = 4; // Kbps
		public var packetSize:int = 500;
		public var interval:int = 1;
		public var startAtSwapin:Boolean = true;
		
		public var unsubmittedChanges:Boolean = true;
		
		public function TrafficFlow(newName:String="")
		{
			super(newName);
		}
	}
}