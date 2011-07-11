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
	
	import protogeni.communication.CommunicationUtil;
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
			super("GetINSTOOLSVersion",
				"Requesting current INSTOOLS version.",
				Instools.instoolsGetVersion,true,true,true);
			op.setUrl(s.manager.Url);
			sliver = s;
			sliver.changing = true;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			//op.setUrl("https://www.uky.emulab.net/protogeni/xmlrpc");
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				Instools.devel_version[sliver.manager.Urn.full.toString()] = String(response.value.devel_version);
				Instools.stable_version[sliver.manager.Urn.full.toString()] = String(response.value.stable_version);
				
				Main.geniHandler.requestHandler.pushRequest(new RequestAddMCNode(sliver));
				
				/*
				LogHandler.appendMessage(new LogMessage(op.getUrl(),
					"GetINSTOOLSVersion",
					String(Main.geniHandler.InstInfo.devel_version[sliver.manager.Urn.full]),
					true,
					LogMessage.TYPE_END));
				*/
			}
			else
			{
				sliver.changing = false;
			}
			
			return null;
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			sliver.changing = false;
			return super.fail(event, fault);
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
