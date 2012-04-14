package com.flack.geni.resources.sites
{
	import com.flack.geni.plugins.emulab.DelaySliverType;
	import com.flack.geni.plugins.emulab.EmulabBbgSliverType;
	import com.flack.geni.plugins.emulab.EmulabOpenVzSliverType;
	import com.flack.geni.plugins.emulab.FirewallSliverType;
	import com.flack.geni.plugins.emulab.RawPcSliverType;
	import com.flack.geni.plugins.planetlab.PlanetlabSliverType;
	import com.flack.geni.plugins.shadownet.JuniperRouterSliverType;
	import com.flack.geni.resources.SliverType;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.virtual.LinkType;
	import com.flack.shared.resources.docs.RspecVersion;

	public class SupportedSliverType
	{
		public var type:SliverType;
		public var supportsExclusive:Boolean = true;
		public var supportsShared:Boolean = true;
		public var supportsBound:Boolean = true;
		public var supportsUnbound:Boolean = true;
		public var supportsInterfaces:Boolean = true;
		public var interfacesUnadvertised:Boolean = false;
		public var supportsDiskImage:Boolean = false;
		public var supportsInstallService:Boolean = false;
		public var supportsExecuteService:Boolean = false;
		public var limitToLinkType:String = "";
		
		public function SupportedSliverType(newName:String)
		{
			type = new SliverType(newName);
			switch(type.name)
			{
				case PlanetlabSliverType.TYPE_PLANETLAB_V1:
				case PlanetlabSliverType.TYPE_PLANETLAB_V2:
				case JuniperRouterSliverType.TYPE_JUNIPER_LROUTER:
					supportsExclusive = false;
					supportsUnbound = false;
					interfacesUnadvertised = true;
					break;
				case EmulabBbgSliverType.TYPE_EMULAB_BBG:
					supportsUnbound = false;
					interfacesUnadvertised = true;
					limitToLinkType = LinkType.VLAN;
					break;
				case "openflow-switch":
					supportsExclusive = false;
					supportsShared = false;
					supportsBound = false;
					supportsUnbound = false;
					break;
				case FirewallSliverType.TYPE_FIREWALL:
				case DelaySliverType.TYPE_DELAY:
					supportsShared = false;
					break;
				case RawPcSliverType.TYPE_RAWPC_V1:
				case RawPcSliverType.TYPE_RAWPC_V2:
					supportsShared = false;
					supportsDiskImage = true;
					supportsInstallService = true;
					supportsExecuteService = true;
					break;
				case EmulabOpenVzSliverType.TYPE_EMULABOPENVZ:
				case SliverTypes.XEN_VM:
				case SliverTypes.QEMUPC:
					supportsInstallService = true;
					supportsExecuteService = true;
				default:
			}
		}
	}
}