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

package com.flack.geni.resources.virtual
{
	import com.flack.geni.resources.Extensions;

	/**
	 * Link type
	 * @author mstrum
	 * 
	 */
	public class LinkType
	{
		public static const LAN_V1:String = "ethernet";
		public static const LAN_V2:String = "lan";
		public static const GRETUNNEL_V1:String = "tunnel";
		public static const GRETUNNEL_V2:String = "gre-tunnel";
		public static const ION:String = "ion";
		public static const GPENI:String = "gpeni";
		public static const VLAN:String = "VLAN";
		
		public var name:String;
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param newName Name of the link type
		 * 
		 */
		public function LinkType(newName:String = LAN_V2)
		{
			name = newName;
		}
	}
}