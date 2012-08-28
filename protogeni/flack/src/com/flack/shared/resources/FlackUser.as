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

package com.flack.shared.resources
{
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.utils.StringUtil;
	import com.mattism.http.xmlrpc.JSLoader;

	/**
	 * GENI user
	 * 
	 * @author mstrum
	 * 
	 */
	public class FlackUser extends IdentifiableObject
	{
		[Bindable]
		public var uid:String = "";
		
		[Bindable]
		public var hrn:String = "";
		[Bindable]
		public var email:String = "";
		[Bindable]
		public var name:String = "";
		
		public var hasSetupSecurity:Boolean = false;
		
		public var password:String = "";
		[Bindable]
		public var sslCert:String = "";
		public function get PrivateKey():String
		{
			var startIdx:int = sslCert.indexOf("-----BEGIN RSA PRIVATE KEY-----");
			var endIdx:int = sslCert.lastIndexOf("-----END RSA PRIVATE KEY-----") + 30;
			if(startIdx != -1 && endIdx != -1)
				return sslCert.substring(startIdx, endIdx);
			else
				return "";
		}
		
		public function FlackUser()
		{
			super();
		}
		
		public function get CertificateSetUp():Boolean
		{
			return hasSetupSecurity;// && (authority != null || credential != null);
		}
		
		/**
		 * 
		 * @param newPassword Password for the user's privake key
		 * @param newCertificate SSL certificate to use
		 * @return TRUE if failed, FALSE if successful
		 * 
		 */
		public function setSecurity(newPassword:String, newCertificate:String):Boolean
		{
			if(newCertificate.length > 0)
			{
				try
				{
					JSLoader.setClientInfo(newPassword, newCertificate);
					password = newPassword;
					sslCert = newCertificate;
					hasSetupSecurity = true;
					return false;
				}
				catch (e:Error)
				{
					SharedMain.logger.add(
						new LogMessage(
							[this],
							"",
							"User Security",
							"Problem setting user credentials in Forge: " + StringUtil.errorToString(e),
							"",
							LogMessage.LEVEL_FAIL
						)
					);
				}
			}
			return true;
		}
	}
}