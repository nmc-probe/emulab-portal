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
	import com.mattism.http.xmlrpc.MethodFault;
	
	import flash.events.ErrorEvent;
	
	import mx.controls.Alert;
	
	import protogeni.GeniEvent;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualComponent;
	import protogeni.resources.VirtualNode;
	
	public final class RequestSliverUpdate extends Request
	{
		public var sliver:Sliver;
		private var request:String = "";
		private var ticket:String = "";
		
		/**
		 * Creates a redeemable ticket for a sliver with a different configuration using the ProtoGENI API
		 * 
		 * @param newSliver
		 * 
		 */
		public function RequestSliverUpdate(newSliver:Sliver, useRspec:XML = null):void
		{
			super("Update sliver @ " + newSliver.manager.Hrn,
				"Updating sliver on " + newSliver.manager.Hrn + " for slice named " + newSliver.slice.Name,
				CommunicationUtil.updateSliver,
				true);
			sliver = newSliver;
			sliver.clearState();
			sliver.changing = true;
			sliver.manifest = null;
			sliver.message = "Waiting to update";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			// Build up the args
			if(useRspec != null)
				request = useRspec.toXMLString()
			else
				request = sliver.getRequestRspec(false).toXMLString();
			
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			sliver.message = "Updating";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			op.clearFields();
			
			op.addField("sliver_urn", sliver.urn.full);
			op.addField("rspec", request);
			op.addField("credentials", [sliver.slice.credential]);
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				ticket = String(response.value);
				sliver.ticket = ticket;
				sliver.message = "Updated ticket recieved";
				var redeemTicket:RequestTicketRedeem = new RequestTicketRedeem(sliver);
				redeemTicket.addAfter = this.addAfter;
				this.addAfter = null;
				redeemTicket.forceNext = true;
				return redeemTicket;
			}
			else
			{
				failed(response.output);
			}
			
			return null;
		}
		
		private function failed(msg:String = ""):void {
			sliver.status = Sliver.STATUS_FAILED;
			sliver.state = Sliver.STATE_NA;
			sliver.changing = false;
			if(msg != null && msg.length > 0)
				sliver.message = msg;
			else
				sliver.message = "Failed to update"
			for each(var node:VirtualNode in sliver.nodes.collection) {
				node.status = VirtualComponent.STATUS_FAILED;
				node.error = "Sliver had error when updating: " + sliver.message;
			}
			
			var managerMsg:String = "";
			if(msg != null && msg.length > 0)
				managerMsg = " Manager reported error: " + msg + ".";
			
			Alert.show("Failed to update sliver on " + sliver.manager.Hrn+"!" + managerMsg, "Failed to create sliver");
			
			// TODO ask user if they want to continue
			
			/*
			// Cancel remaining calls
			var tryDeleteNode:RequestQueueNode = this.node.next;
			while(tryDeleteNode != null && tryDeleteNode.item is RequestSliverCreate && (tryDeleteNode.item as RequestSliverCreate).sliver.slice == sliver.slice)
			{
			(tryDeleteNode.item as RequestSliverCreate).sliver.status = Sliver.STATUS_FAILED;
			(tryDeleteNode.item as RequestSliverCreate).sliver.state = Sliver.STATE_NA;
			Main.geniHandler.requestHandler.remove(tryDeleteNode.item, false);
			tryDeleteNode = tryDeleteNode.next;
			}
			
			// Show the error
			LogHandler.viewConsole();
			*/
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			var msg:String = "";
			if(fault != null)
				msg = fault.getFaultString();
			failed(msg);
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
		
		override public function getSent():String {
			return "******** REQUEST RSPEC ********\n\n" + request + "\n\n******** XML-RPC ********" + op.getSent();
		}
		
		override public function getResponse():String {
			return "******** TICKET ********\n\n" + ticket + "\n\n******** XML-RPC ********" + op.getResponse();
		}
	}
}
