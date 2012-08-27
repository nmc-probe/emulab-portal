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
	
	public class VirtualInterface extends NamedObject
	{
		public var node:VirtualNode;
		public var link:VirtualLink;
		public var ip:String = "";
		public var physicalName:String = ""; // usually not set
		
		public var queue:Queue = null; // queue from this interface out
		
		public var tracing:String = "";
		public var filter:String = "";
		public var captureLength:int = -1;
		
		public var bandwidthFrom:Number = 100000; //kbs
		public var latencyFrom:Number = 0; //ms
		public var lossRateFrom:Number = 0; //out of 1
		// LAN ONLY
		public var bandwidthTo:Number = 100000; //kbs
		public var latencyTo:Number = 0; //ms
		public var lossRateTo:Number = 0; //out of 1
		
		public function VirtualInterface(newNode:VirtualNode, newName:String="")
		{
			super(newName);
			node = newNode;
		}
	}
}