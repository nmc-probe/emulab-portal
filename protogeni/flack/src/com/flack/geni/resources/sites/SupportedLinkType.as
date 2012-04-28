package com.flack.geni.resources.sites
{
	import com.flack.geni.plugins.emulab.EmulabBbgSliverType;
	import com.flack.geni.resources.SliverType;
	import com.flack.geni.resources.SliverTypeCollection;
	import com.flack.geni.resources.virtual.LinkType;

	public class SupportedLinkType
	{
		public var name:String;
		public var maxConnections:Number = Number.POSITIVE_INFINITY;
		public var supportsManyManagers:Boolean = false;
		public var requiresIpAddresses:Boolean = false;
		public var supportsSameManager:Boolean = true;
		public var defaultCapacity:Number = NaN;
		public var level:int = int.MAX_VALUE;
		
		public function SupportedLinkType(newName:String)
		{
			name = newName;
			switch(name)
			{
				case LinkType.VLAN:
					maxConnections = 2;
					supportsManyManagers = true;
					defaultCapacity = 500;
					level = 1500;
					break;
				case LinkType.ION:
				case LinkType.GPENI:
					maxConnections = 2;
					supportsManyManagers = true;
					supportsSameManager = false;
					level = 100;
					break;
				case LinkType.GRETUNNEL_V1:
				case LinkType.GRETUNNEL_V2:
					maxConnections = 2;
					supportsManyManagers = true;
					requiresIpAddresses = true;
					level = 50;
					break;
				case LinkType.LAN_V2:
					level = 0;
					break;
				case LinkType.UNSPECIFIED:
					supportsManyManagers = true;
					level = 1000;
					break;
				default:
			}
		}
		
		public function get Clone():SupportedLinkType
		{
			var clone:SupportedLinkType = new SupportedLinkType(name);
			clone.maxConnections = maxConnections;
			clone.supportsManyManagers = supportsManyManagers;
			clone.requiresIpAddresses = requiresIpAddresses;
			clone.supportsSameManager = supportsSameManager;
			clone.level = level;
			return clone;
		}
	}
}