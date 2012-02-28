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
	 * Services
	 * 
	 * @author mstrum
	 * 
	 */
	public class Services
	{
		public var installServices:Vector.<InstallService> = null;
		public var executeServices:Vector.<ExecuteService> = null;
		public var loginServices:Vector.<LoginService> = null;
		
		public var extensions:Extensions = new Extensions();
		
		public function Services()
		{
		}
	}
}