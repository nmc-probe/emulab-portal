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
	import protogeni.communication.RequestQueue;
	import protogeni.communication.RequestQueueNode;
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
			super("Poll Instools Status @ " + newSliver.manager.Hrn,
				"Getting the sliver status on " + newSliver.manager.Hrn + " on slice named " + newSliver.slice.Name,
				Instools.instoolsGetInstoolsStatus,
				true,
				true);
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Waiting to poll INSTOOLS status...";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			// Make sure we're working on the most recent sliver
			sliver = Main.geniHandler.CurrentUser.slices.getByUrn(sliver.slice.urn.full).slivers.getByManager(sliver.manager);
			if(this.op.delaySeconds == 0)
				sliver.message = "Polling INSTOOLS status...";
			sliver.changing = true;
			sliver.status = Sliver.STATUS_CHANGING;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.addField("urn", sliver.slice.urn.full);
			op.addField("INSTOOLS_VERSION",Instools.devel_version[sliver.manager.Urn.full.toString()]);
			op.addField("credentials", new Array(sliver.slice.credential));
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				// Try again if we need
				var req:Request = null;
				var reqQueue:RequestQueue = new RequestQueue();
				this.op.delaySeconds = 30;
				
				Instools.instools_status[sliver.manager.Urn.full] = String(response.value.status);
				var status:String = String(response.value.status);
				switch(status) {
					case "INSTRUMENTIZE_COMPLETE":		//instrumentize is finished, experiment is ready, etc.
						Instools.portal_url[sliver.manager.Urn.full] = String(response.value.portal_url);
						sliver.changing = false;
						sliver.status = Sliver.STATUS_READY;
						sliver.message = "Instrumentizing complete!";
						break;
					case "INSTALLATION_COMPLETE":		//MC has finished the startup scripts
						sliver.message = "Instrumentize scripts installed...";
						sliver.status = Sliver.STATUS_CHANGING;
						if (Instools.started_instrumentize[sliver.manager.Urn.full] != "1")
						{
							req = new RequestInstrumentize(sliver);
							req.forceNext = true;
							reqQueue.push(req);
							Instools.started_instrumentize[sliver.manager.Urn.full] = "1";
						}
						reqQueue.push(this);
						break;
					case "MC_NOT_STARTED":				//MC has been added, but not started
						sliver.message = "MC not started...";
						sliver.status = Sliver.STATUS_CHANGING;
						if (Instools.started_MC[sliver.manager.Urn.full] != "1")
						{
							req = new RequestSliverStart(sliver);
							req.forceNext = true;
							reqQueue.push(req);
							Instools.started_MC[sliver.manager.Urn.full] = "1";
						}
						reqQueue.push(this);
						break;
					case "INSTRUMENTIZE_IN_PROGRESS":	//the instools server has started instrumentizing the nodes
						sliver.message = "Instrumentize in progress...";
						sliver.status = Sliver.STATUS_CHANGING;
						reqQueue.push(this);
						break;
					case "INSTALLATION_IN_PROGRESS":	//MC is running it's startup scripts
						sliver.message = "Instrumentize installing...";
						sliver.status = Sliver.STATUS_CHANGING;
						reqQueue.push(this);
						break;
					case "MC_NOT_PRESENT":				//The addMC/updatesliver calls haven't finished 
						sliver.message = "MC Node not added yet...";
						sliver.status = Sliver.STATUS_CHANGING;
						reqQueue.push(this);
						break;
					case "MC_UNSUPPORTED_OS":
						sliver.message = "Unsupported OS! Maybe not booted...";
						sliver.status = Sliver.STATUS_CHANGING;
						reqQueue.push(this);
						break;
					default:
						sliver.status = Sliver.STATUS_FAILED;
						sliver.changing = false;
						sliver.message = status + "!";
						Alert.show("Unrecognized INSTOOLS status: " + status);
						break;
				}
				
				return reqQueue.head;
			} else
				failed(response.output);
			
			return null;
		}
		
		public function failed(msg:String = ""):void {
			sliver.changing = false;
			sliver.message = "Poll INSTOOLS status failed";
			Alert.show("Failed to poll INSTOOLS status on " + sliver.manager.Hrn + ". " + msg, "Problem polling INSTOOLS status");
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			failed(fault.getFaultString());
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
		}
	}
}
