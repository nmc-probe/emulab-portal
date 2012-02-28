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

package com.flack.geni.resources
{
	public class SliverTypes
	{
		// V1
		static public var RAWPC_V1:String = "raw";
		public static var EMULAB_VNODE:String = "emulab-vnode";
		static public var JUNIPER_LROUTER:String = "juniper-lrouter";
		
		// V2
		static public var DELAY:String = "delay";
		static public var FIREWALL:String = "firewall";
		static public var RAWPC_V2:String = "raw-pc";
		static public var EMULAB_OPENVZ:String = "emulab-openvz";
		
		// Planet-lab
		static public var PLANETLAB_V1:String = "plab-vnode";
		static public var PLANETLAB_V2:String = "plab-vserver";
		
		static public var XEN_VM:String = "xen-vm";
		
		// OpenFlow
		static public var OPENFLOW_SWITCH:String = "openflow-switch";
		
		/**
		 * Is the sliver_type a virtual machine instead of being raw metal?
		 * 
		 * @param name name of sliver_type
		 * @return TRUE if sliver_type is not a raw resource
		 * 
		 */
		static public function isVm(name:String):Boolean
		{
			switch(name)
			{
				case JUNIPER_LROUTER:
				case EMULAB_OPENVZ:
				case PLANETLAB_V1:
				case PLANETLAB_V2:
				case XEN_VM:
				case OPENFLOW_SWITCH:
					return true;
				default:
					return false;
			}
		}
		
	}
}