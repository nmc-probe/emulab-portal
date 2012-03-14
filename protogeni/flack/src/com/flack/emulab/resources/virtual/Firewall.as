package com.flack.emulab.resources.virtual
{
	public class Firewall
	{
		static public const TYPE_IPFW2VLAN:String = "ipfw2-vlan";
		
		static public const STYLE_BASIC:String = "basic";
		static public const STYLE_CLOSED:String = "closed";
		static public const STYLE_OPEN:String = "open";
		
		public var type:String = "";
		public var style:String = "";
		public var rules:Vector.<NumberValuePair> = new Vector.<NumberValuePair>();
		
		public function Firewall()
		{
		}
	}
}