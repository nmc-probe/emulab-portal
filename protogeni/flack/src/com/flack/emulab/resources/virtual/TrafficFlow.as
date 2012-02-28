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