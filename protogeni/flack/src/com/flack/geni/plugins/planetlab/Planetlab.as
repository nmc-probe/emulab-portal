package com.flack.geni.plugins.planetlab
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	import com.flack.geni.resources.SliverTypes;
	
	public class Planetlab implements Plugin
	{
		public function get Title():String { return "Planetlab" };
		public function get Area():PluginArea { return null; };
		
		public function Planetlab()
		{
			super();
		}
		
		public function init():void
		{
			SliverTypes.addSliverTypeInterface(PlanetlabSliverType.TYPE_PLANETLAB_V1, new PlanetlabSliverType());
			SliverTypes.addSliverTypeInterface(PlanetlabSliverType.TYPE_PLANETLAB_V2, new PlanetlabSliverType());
		}
	}
}