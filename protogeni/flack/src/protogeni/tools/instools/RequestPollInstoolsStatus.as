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
	import mx.controls.Alert;
	
	import protogeni.communication.CommunicationUtil;
	import protogeni.communication.Request;
	import protogeni.communication.RequestSliverStart;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualNode;
	
	/**
	 * Polls a sliver for the instools status
	 * 
	 * @author jreed
	 * 
	 */
	public final class RequestPollInstoolsStatus extends Request
	{
		public var sliver:Sliver;
		public function RequestPollInstoolsStatus(newSliver:Sliver):void
		{
			super("Poll InstoolsStatus",
				"Getting the sliver status on " + newSliver.manager.Hrn + " on slice named " + newSliver.slice.hrn,
				Instools.instoolsGetInstoolsStatus,
				true,
				true);
			sliver = newSliver;
			sliver.changing = true;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			// Build up the args
			op.addField("urn", sliver.slice.urn.full);
			op.addField("INSTOOLS_VERSION",Instools.devel_version[sliver.manager.Urn.full.toString()]);
			op.addField("credentials", new Array(sliver.slice.credential));
			op.setUrl(sliver.manager.Url);
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				// Try again if we need
				var req:RequestPollInstoolsStatus = new RequestPollInstoolsStatus(sliver);
				req.op.delaySeconds = 30;
				
				Instools.instools_status[sliver.manager.Urn.full] = String(response.value.status);
				var status:String = String(response.value.status);
				switch(status) {
					case "INSTRUMENTIZE_COMPLETE":		//instrumentize is finished, experiment is ready, etc.
						Instools.portal_url[sliver.manager.Urn.full] = String(response.value.portal_url);
						sliver.changing = false;
						break;
					case "INSTALLATION_COMPLETE":		//MC has finished the startup scripts
						if (Instools.started_instrumentize[sliver.manager.Urn.full] != "1")
						{
							var req1:RequestInstrumentize = new RequestInstrumentize(sliver);
							Main.geniHandler.requestHandler.pushRequest(req1);
							Instools.started_instrumentize[sliver.manager.Urn.full] = "1";
						}
						break;
					case "MC_NOT_STARTED":				//MC has been added, but not started
						if (Instools.started_MC[sliver.manager.Urn.full] != "1")
						{
							Main.geniHandler.requestHandler.pushRequest(new RequestSliverStart(sliver));
							Instools.started_MC[sliver.manager.Urn.full] = "1";
						}
						break;
					case "INSTRUMENTIZE_IN_PROGRESS":	//the instools server has started instrumentizing the nodes
					case "INSTALLATION_IN_PROGRESS":	//MC is running it's startup scripts
					case "MC_NOT_PRESENT":				//The addMC/updatesliver calls haven't finished 
					case "MC_UNSUPPORTED_OS":
						break;
					default:
						Alert.show("Unrecognized INSTOOLS status: " + status);
						break;
				}
				
				return req;
			}
			
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
