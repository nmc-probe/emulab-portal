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
	 * Login available to the user
	 * 
	 * @author mstrum
	 * 
	 */
	public class LoginService
	{
		public var authentication:String;
		public var hostname:String;
		public function get FullHostname():String
		{
			return hostname + (port.length>0 ? ":"+port : "");
		}
		public var port:String;
		public var username:String;
		public function get FullLogin():String
		{
			return (username.length > 0 ? username + "@" : "") + FullHostname;
		}
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param newAuth Type of authentication
		 * @param newHost Hostname
		 * @param newPort Port
		 * @param newUser Username
		 * 
		 */
		public function LoginService(newAuth:String = "",
									 newHost:String = "",
									 newPort:String = "",
									 newUser:String = "")
		{
			authentication = newAuth;
			hostname = newHost;
			port = newPort;
			username = newUser;
		}
	}
}