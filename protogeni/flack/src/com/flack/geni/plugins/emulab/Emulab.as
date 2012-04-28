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
			SliverTypes.addSliverTypeInterface(RawPcSliverType.TYPE_RAWPC_V1, new RawPcSliverType());
			SliverTypes.addSliverTypeInterface(RawPcSliverType.TYPE_RAWPC_V2, new RawPcSliverType());
			SliverTypes.addSliverTypeInterface(EmulabOpenVzSliverType.TYPE_EMULABOPENVZ, new EmulabOpenVzSliverType());
			SliverTypes.addSliverTypeInterface(EmulabBbgSliverType.TYPE_EMULAB_BBG, new EmulabBbgSliverType());
			SliverTypes.addSliverTypeInterface(EmulabSppSliverType.TYPE_EMULAB_SPP, new EmulabSppSliverType());
			SliverTypes.addSliverTypeInterface(Netfpga2SliverType.TYPE_NETFPGA2, new Netfpga2SliverType());
		}
	}
}