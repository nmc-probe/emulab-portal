package com.flack.geni.plugins.shadownet
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	
	public class Shadownet implements Plugin
	{
		public function Shadownet()
		{
		}
		
		public function get Title():String
		{
			return "Shadownet";
		}
		
		public function get Area():PluginArea
		{
			return null;
		}
		
		public function init():void
		{
		}
	}
}