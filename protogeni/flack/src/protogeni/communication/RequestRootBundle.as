/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2011 University of Utah and the Flux Group.
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

package protogeni.communication
{
	import com.mattism.http.xmlrpc.JSLoader;
	import com.mattism.http.xmlrpc.MethodFault;
	
	import flash.events.ErrorEvent;
	
	/**
	 * Gets the current ProtoGENI root bundle
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestRootBundle extends Request
	{
		public function RequestRootBundle():void
		{
			super("Get root bundle",
				"Getting root bundle",
				null,
				true);
			
			op.type = Operation.HTTP;
			op.timeout = 20;
			op.setExactUrl(Main.geniHandler.rootBundleUrl);
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				FlackCache.rootBundle = response as String;
				FlackCache.saveBasic();
				JSLoader.setServerCertificate(FlackCache.geniBundle + FlackCache.rootBundle);
			}
			
			return null;
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):*
		{
			if(FlackCache.rootBundle.length == 0)
				FlackCache.rootBundle = (new FallbackRootBundle()).toString();
			FlackCache.saveBasic();
			JSLoader.setServerCertificate("-----BEGIN CERTIFICATE-----\n" + 
				"MIICLzCCAZigAwIBAgIETgDrgzANBgkqhkiG9w0BAQUFADBcMQswCQYDVQQGEwJV\n" + 
				"UzELMAkGA1UECBMCTUExEjAQBgNVBAcTCUNhbWJyaWRnZTENMAsGA1UEChMER0VO\n" + 
				"STEMMAoGA1UECxMDR1BPMQ8wDQYDVQQDEwZHUE8gQU0wHhcNMTEwNjIxMTkwNTM5\n" + 
				"WhcNMTEwOTE5MTkwNTM5WjBcMQswCQYDVQQGEwJVUzELMAkGA1UECBMCTUExEjAQ\n" + 
				"BgNVBAcTCUNhbWJyaWRnZTENMAsGA1UEChMER0VOSTEMMAoGA1UECxMDR1BPMQ8w\n" + 
				"DQYDVQQDEwZHUE8gQU0wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAIGRUysM\n" + 
				"69UOg9VJs0cZoCQA1DpTeuzzkqA6VMfyRS5D+yBOFXExUIXnlsnJyMvCNWtfQ5gz\n" + 
				"uX0q+T9e5tHiB3u5HESGIOB3FTigdKq8Fpyzxbk4llps8g5FYHSkwtDS4ENnKCXM\n" + 
				"2X2Hk0TWBTpghgY9RRnzDxPC/thWVYRsO2LpAgMBAAEwDQYJKoZIhvcNAQEFBQAD\n" + 
				"gYEAS51LgxUkB9LsiNZWZstlzynTOmoNvVy55swAJmyPieePaIi9W0y4lrqswEV1\n" + 
				"a/MWqnEm74uTLLj0mVRSUHL6PUFDmT4JM5/0Gv05GZO7et7p4WIrf5jmd0XEKvMt\n" + 
				"4dj1um7sEs+HeRLqQMG7MkUIK3s/aiq130cKHhb1oQnSbss=\n" + 
				"-----END CERTIFICATE-----\n" + FlackCache.geniBundle + FlackCache.rootBundle);
		}
	}
}
