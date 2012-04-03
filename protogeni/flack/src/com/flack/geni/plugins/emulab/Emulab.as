package com.flack.geni.plugins.emulab
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	import com.flack.geni.resources.SliverTypes;
	
	public class Emulab implements Plugin
	{
		public function get Title():String { return "Emulab" };
		public function get Area():PluginArea { return new EmulabArea(); };
		
		public function Emulab()
		{
			super();
		}
		
		public function init():void
		{
			SliverTypes.addSliverTypeInterface(DelaySliverType.TYPE_DELAY, new DelaySliverType());
			SliverTypes.addSliverTypeInterface(FirewallSliverType.TYPE_FIREWALL, new FirewallSliverType());
		}
	}
}