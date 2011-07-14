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
	import protogeni.communication.RequestQueueNode;
	import protogeni.communication.RequestSliverUpdate;
	import protogeni.resources.Sliver;
	
	/**
	 * Adds a MC Node to a sliver
	 * 
	 * @author jreed
	 * 
	 */
	public final class RequestAddMCNode extends Request
	{
		public var sliver:Sliver;
		
		public function RequestAddMCNode(s:Sliver):void
		{
			super("Add MC Node @ " + s.manager.Hrn,
				"Allocating a measurement controller at " + s.manager.Hrn,
				Instools.instoolsAddMCNode,
				true,
				true);
			sliver = s;
			sliver.changing = true;
			sliver.message = "Waiting to add MC Node";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			// Build up the args
			op.addField("urn", sliver.slice.urn.full);
			//we currently do not support virtual nodes as MCs
			op.addField("virtualMC", 0);
			op.addField("INSTOOLS_VERSION",Instools.devel_version[sliver.manager.Urn.full.toString()]);
			op.addField("credentials", [sliver.slice.credential]);
			//op.setUrl("https://www.uky.emulab.net/protogeni/xmlrpc");
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			sliver.message = "Adding MC Node";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
			  if (response.value.wasMCpresent) 
			  {
				  sliver.message = "MC Node already added";
				  Main.geniHandler.requestHandler.pushRequest(new RequestPollInstoolsStatus(sliver));
			  } 
			  else 
			  {
				  sliver.message = "MC Node added";
				  Instools.updated_rspec[sliver.manager.Urn.full] = String(response.value.instrumentized_rspec);
				  Instools.rspec_version[sliver.manager.Urn.full] = String(response.value.rspec_version);
				  var pollStatus:RequestPollInstoolsStatus = new RequestPollInstoolsStatus(sliver);
				  var requestNewNode:RequestSliverUpdate = new RequestSliverUpdate(sliver, new XML(response.value.instrumentized_rspec));
				  requestNewNode.forceNext = true;
				  requestNewNode.addAfter = new RequestQueueNode(pollStatus);
				  Main.geniHandler.requestHandler.pushRequest(requestNewNode);
			  }
			}
			else
			{
				failed(String(response.output));
			}
			
			return null;
		}
		
		public function failed(msg:String = ""):void {
			sliver.changing = false;
			sliver.message = "Add MC Node failed";
			Alert.show("There was a problem adding the MC Node on " + sliver.manager.Hrn + ". " + msg, "Problem adding MC Node");
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
