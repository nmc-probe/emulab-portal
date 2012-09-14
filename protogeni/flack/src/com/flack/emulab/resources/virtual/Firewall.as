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

package com.flack.emulab.resources.virtual
{
	public class Firewall
	{
		static public const TYPE_IPFW2VLAN:String = "ipfw2-vlan";
		
		static public const STYLE_BASIC:String = "basic";
		static public const STYLE_CLOSED:String = "closed";
		static public const STYLE_OPEN:String = "open";
		
		public var type:String = "";
		public var style:String = "";
		public var rules:Vector.<NumberValuePair> = new Vector.<NumberValuePair>();
		
		public function Firewall()
		{
		}
	}
}