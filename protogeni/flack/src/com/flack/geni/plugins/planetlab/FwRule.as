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

package com.flack.geni.plugins.planetlab
{
	public class FwRule
	{
		public var protocol:String;
		public var portRange:String;
		public var cidrIp:String;
		
		public function FwRule(newProtocol:String = "",
							   newPortRange:String = "",
							   newCidrIp:String = "")
		{
			protocol = newProtocol;
			portRange = newPortRange;
			cidrIp = newCidrIp;
		}
		
		public function get Empty():Boolean
		{
			return protocol.length == 0 && portRange.length == 0 && cidrIp.length == 0;
		}
		
		public function ToString():String
		{
			return protocol + "; " + portRange + "; " + cidrIp;
		}
	}
}