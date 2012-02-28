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
		}
	}
}