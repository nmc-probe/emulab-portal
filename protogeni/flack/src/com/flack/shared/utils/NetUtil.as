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

package com.flack.shared.utils
{
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.Security;
	import flash.utils.Dictionary;
	
	import mx.core.FlexGlobals;
	
	/**
	 * Common functions used for web stuff
	 * 
	 * @author mstrum
	 * 
	 */
	public final class NetUtil
	{
		public static const flashSocketSecurityPolicyUrl:String = "http://www.protogeni.net/trac/protogeni/wiki/FlackManual#AddingaFlashSocketSecurityPolicyServer";
		public static function openWebsite(url:String):void
		{
			navigateToURL(new URLRequest(url), "_blank");
		}
		
		public static function openMail(receiverEmail:String, subject:String, body:String):void
		{
			var mailRequest:URLRequest = new URLRequest("mailto:" + receiverEmail);
			var mailVariables:URLVariables = new URLVariables();
			mailVariables.subject = subject;
			mailVariables.body = body;
			mailRequest.data = mailVariables;
			navigateToURL(mailRequest, "_blank");
		}
		
		public static function runningFromWebsite():Boolean
		{
			return FlexGlobals.topLevelApplication.url.toLowerCase().indexOf("http") == 0;
		}
		
		public static function tryGetBaseUrl(url:String):String
		{
			var hostPattern:RegExp = /^(http(s?):\/\/([^\/]+))(\/.*)?$/;
			var match : Object = hostPattern.exec(url);
			if (match != null)
			{
				if((match[1] as String).split(":").length > 2)
					return (match[1] as String).substr(0, (match[1] as String).lastIndexOf(":"));
				else
					return match[1] as String;
			}
			else
				return url;
		}
		
		public static function getBrowserName():String
		{
			var browser:String;
			var browserAgent:String = ExternalInterface.call("function getBrowser(){return navigator.userAgent;}");
			
			if(browserAgent == null)
				return "Undefined";
			else if(browserAgent.indexOf("Firefox") >= 0)
				browser = "Firefox";
			else if(browserAgent.indexOf("Safari") >= 0)
				browser = "Safari";
			else if(browserAgent.indexOf("MSIE") >= 0)
				browser = "IE";
			else if(browserAgent.indexOf("Opera") >= 0)
				browser = "Opera";
			else
				browser = "Undefined";
			
			return (browser);
		}
		
		// Takes the given bandwidth and creates a human readable string
		public static function kbsToString(bandwidth:Number):String
		{
			if(bandwidth < 1000)
				return bandwidth + " Kb/s";
			else if(bandwidth < 1000000)
				return bandwidth / 1000 + " Mb/s";
			else
				return bandwidth / 1000000 + " Gb/s";
		}
		
		private static var visitedSites:Dictionary = new Dictionary();
		public static function checkLoadCrossDomain(url:String):void
		{
			var baseUrl:String = tryGetBaseUrl(url);
			if (visitedSites[baseUrl] == null)
			{
				visitedSites[baseUrl] = true;
				
				Security.loadPolicyFile(baseUrl + "/crossdomain.xml");
				Security.loadPolicyFile(baseUrl + "/protogeni/crossdomain.xml");
			}
		}
	}
}