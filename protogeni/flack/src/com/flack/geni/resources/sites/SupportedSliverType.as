/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

package com.flack.geni.resources.sites
{
	import com.flack.geni.plugins.emulab.DelaySliverType;
	import com.flack.geni.plugins.emulab.EmulabBbgSliverType;
	import com.flack.geni.plugins.emulab.EmulabOpenVzSliverType;
	import com.flack.geni.plugins.emulab.EmulabSppSliverType;
	import com.flack.geni.plugins.emulab.FirewallSliverType;
	import com.flack.geni.plugins.emulab.Netfpga2SliverType;
	import com.flack.geni.plugins.emulab.RawPcSliverType;
	import com.flack.geni.plugins.planetlab.M1LargeSliverType;
	import com.flack.geni.plugins.planetlab.M1MediumSliverType;
	import com.flack.geni.plugins.planetlab.M1SmallSliverType;
	import com.flack.geni.plugins.planetlab.M1TinySliverType;
	import com.flack.geni.plugins.planetlab.M1WorkerSliverType;
	import com.flack.geni.plugins.planetlab.M1XLargeSliverType;
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
		public var defaultExclusiveSetting:Boolean = true;
		public var supportsBound:Boolean = true;
		public var supportsUnbound:Boolean = true;
		public var supportsInterfaces:Boolean = true;
		public var interfacesUnadvertised:Boolean = false;
		public var supportsDiskImage:Boolean = true;
		public var supportsInstallService:Boolean = true;
		public var supportsExecuteService:Boolean = true;
		public var limitToLinkType:String = "";
		
		// TODO(mstrum): This needs to go away. Push all of these sliver type
		// configurations into their respective plugins.
		public function SupportedSliverType(newName:String)
		{
			type = new SliverType(newName);
			switch(type.name)
			{
				case M1TinySliverType.TYPE_M1TINY:
				case M1SmallSliverType.TYPE_M1SMALL:
				case M1MediumSliverType.TYPE_M1MEDIUM:
				case M1LargeSliverType.TYPE_M1LARGE:
				case M1XLargeSliverType.TYPE_M1XLARGE:
				case M1WorkerSliverType.TYPE_M1WORKER:
					supportsExclusive = false;
					defaultExclusiveSetting = false;
					interfacesUnadvertised = true;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case PlanetlabSliverType.TYPE_PLANETLAB_V1:
				case PlanetlabSliverType.TYPE_PLANETLAB_V2:
				case JuniperRouterSliverType.TYPE_JUNIPER_LROUTER:
					supportsExclusive = false;
					defaultExclusiveSetting = false;
					supportsUnbound = false;
					interfacesUnadvertised = true;
					supportsDiskImage = false;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case EmulabBbgSliverType.TYPE_EMULAB_BBG:
					supportsUnbound = false;
					interfacesUnadvertised = true;
					limitToLinkType = LinkType.VLAN;
					supportsDiskImage = false;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case EmulabSppSliverType.TYPE_EMULAB_SPP:
					supportsUnbound = false;
					supportsDiskImage = false;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case "openflow-switch":
					supportsExclusive = false;
					supportsShared = false;
					supportsBound = false;
					supportsUnbound = false;
					supportsDiskImage = false;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case FirewallSliverType.TYPE_FIREWALL:
				case DelaySliverType.TYPE_DELAY:
					supportsShared = false;
					supportsDiskImage = false;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case RawPcSliverType.TYPE_RAWPC_V1:
				case RawPcSliverType.TYPE_RAWPC_V2:
					supportsShared = false;
					break;
				case Netfpga2SliverType.TYPE_NETFPGA2:
					supportsUnbound = false;
					supportsShared = false;
					supportsDiskImage = false;
					supportsInstallService = false;
					supportsExecuteService = false;
					break;
				case EmulabOpenVzSliverType.TYPE_EMULABOPENVZ:
				case SliverTypes.XEN_VM:
				case SliverTypes.QEMUPC:
					supportsDiskImage = false;
				default:
			}
		}
	}
}