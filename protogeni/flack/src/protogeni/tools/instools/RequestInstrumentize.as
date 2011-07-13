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

package protogeni.tools.instools
{
	import com.adobe.crypto.SHA1;
	import com.mattism.http.xmlrpc.MethodFault;
	
	import flash.events.ErrorEvent;
	
	import mx.controls.Alert;
	
	import protogeni.GeniEvent;
	import protogeni.Util;
	import protogeni.communication.CommunicationUtil;
	import protogeni.communication.Operation;
	import protogeni.communication.Request;
	import protogeni.resources.Sliver;
	
	/**
	 * Instruments a sliver
	 * 
	 * @author jreed
	 * 
	 */
	public final class RequestInstrumentize extends Request
	{
		public var sliver:Sliver;
		public function RequestInstrumentize(s:Sliver):void
		{
			super("Instrumentize @ " + s.manager.Hrn,
				"Instrumentizing the experiment on " + s.manager.Hrn,
				Instools.instoolsInstrumentize,
				true,
				true);
			op.setUrl(s.manager.Url);
			sliver = s;
			sliver.changing = true;
			sliver.message = "Waiting to instrumentize";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.addField("urn", sliver.slice.urn.full);
			//we currently do not support virtual nodes as MCs
			
			//var passwd:String = Util.rc4encrypt("secretkey",Main.geniHandler.CurrentUser.passwd);
			//passwd = encodeURI(passwd);
			var passwd:String;
			passwd = SHA1.hash(Main.geniHandler.CurrentUser.passwd);
			
			op.addField("password", passwd);
			op.addField("INSTOOLS_VERSION",Instools.devel_version[sliver.manager.Urn.full.toString()]);
			op.addField("credentials", [sliver.slice.credential]);
			//op.setUrl("https://www.uky.emulab.net/protogeni/xmlrpc");
		}
		
		override public function start():Operation {
			sliver.message = "Instrumentizing";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			sliver.message = "Instrumentized";
			
			return null;
		}
		
		public function failed(msg:String = ""):void {
			sliver.message = "Instrumentizing failed";
			if(msg != null && msg.length > 0)
				sliver.message += ": " + msg;
			Alert.show("Failed to Instrumentize on " + sliver.manager.Hrn + ". " + msg, "Problem instrumentizing");
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			failed(fault.getFaultString());
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			sliver.changing = false;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
