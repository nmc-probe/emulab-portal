package com.flack.geni.resources.sites
{
	import com.flack.geni.resources.virtual.LinkType;

	public class SupportedLinkType
	{
		public var name:String;
		public var maxConnections:Number = Number.POSITIVE_INFINITY;
		public var supportsManyManagers:Boolean = false;
		public var supportsSameManager:Boolean = true;
		
		public function SupportedLinkType(newName:String)
		{
			name = newName;
			switch(name)
			{
				case LinkType.ION:
				case LinkType.GPENI:
					maxConnections = 2;
					supportsManyManagers = true;
					supportsSameManager = false;
					break;
				case LinkType.GRETUNNEL_V1:
				case LinkType.GRETUNNEL_V2:
					maxConnections = 2;
					supportsManyManagers = true;
					break;
				case LinkType.LAN_V2:
				default:
			}
		}
	}
}