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
	import com.mattism.http.xmlrpc.MethodFault;
	
	import flash.events.ErrorEvent;
	
	import mx.controls.Alert;
	
	import protogeni.GeniEvent;
	import protogeni.communication.CommunicationUtil;
	import protogeni.communication.Operation;
	import protogeni.communication.Request;
	import protogeni.resources.Sliver;
	
	/**
	 * Restarts a sliver using the ProtoGENI API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestInstoolsVersion extends Request
	{
		public var sliver:Sliver;
		public function RequestInstoolsVersion(s:Sliver):void
		{
			super("Get INSTOOLS version @ " + s.manager.Hrn,
				"Requesting current INSTOOLS version at " + s.manager.Hrn,
				Instools.instoolsGetVersion,
				true,
				true);
			sliver = s;
			sliver.changing = true;
			sliver.message = "Waiting to get INSTOOLS version";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			//op.setUrl("https://www.uky.emulab.net/protogeni/xmlrpc");
			op.setUrl(s.manager.Url);
		}
		
		override public function start():Operation {
			sliver.message = "Getting INSTOOLS version";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				Instools.devel_version[sliver.manager.Urn.full] = String(response.value.devel_version);
				Instools.stable_version[sliver.manager.Urn.full] = String(response.value.stable_version);
				
				sliver.message = "Got INSTOOLS version";
				
				return new RequestAddMCNode(sliver);
				
				/*
				LogHandler.appendMessage(new LogMessage(op.getUrl(),
					"GetINSTOOLSVersion",
					String(Main.geniHandler.InstInfo.devel_version[sliver.manager.Urn.full]),
					true,
					LogMessage.TYPE_END));
				*/
			}
			else
				failed(response.output);
			
			return null;
		}
		
		public function failed(msg:String = ""):void {
			sliver.changing = false;
			sliver.message = "Get INSTOOLS version failed";
			Alert.show("Failed to get INSTOOLS version on " + sliver.manager.Hrn + ". " + msg, "Problem getting INSTOOLS version");
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			failed(fault.getFaultString());
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
