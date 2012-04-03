package com.flack.geni.plugins.openflow
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	import com.flack.geni.resources.SliverTypes;
	
	public class Openflow implements Plugin
	{
		public function get Title():String { return "OpenFlow" };
		public function get Area():PluginArea { return null; };
		
		public function Openflow()
		{
			super();
		}
		
		public function init():void
		{
			var newProcessor:OpenflowRspecProcessor = new OpenflowRspecProcessor();
			SliverTypes.addRspecProcessInterface(newProcessor.namespace.uri, newProcessor);
		}
	}
}