package com.flack.geni.resources.sites
{
	import com.flack.geni.resources.SliverType;
	import com.flack.geni.resources.SliverTypes;

	public class SupportedSliverType
	{
		public var type:SliverType;
		public var supportsExclusive:Boolean = true;
		public var supportsShared:Boolean = true;
		public var supportsBound:Boolean = true;
		public var supportsUnbound:Boolean = true;
		
		public function SupportedSliverType(newName:String)
		{
			type = new SliverType(newName);
			switch(type.name)
			{
				case SliverTypes.PLANETLAB_V1:
				case SliverTypes.PLANETLAB_V2:
				case SliverTypes.JUNIPER_LROUTER:
					supportsExclusive = false;
					supportsUnbound = false;
					break;
				case SliverTypes.OPENFLOW_SWITCH:
					supportsExclusive = false;
					supportsShared = false;
					supportsBound = false;
					supportsUnbound = false;
					break;
				case SliverTypes.FIREWALL:
				case SliverTypes.DELAY:
				case SliverTypes.RAWPC_V1:
				case SliverTypes.RAWPC_V2:
					supportsShared = false;
					break;
				case SliverTypes.EMULAB_OPENVZ:
				case SliverTypes.XEN_VM:
				case SliverTypes.QEMUPC:
				default:
			}
		}
	}
}