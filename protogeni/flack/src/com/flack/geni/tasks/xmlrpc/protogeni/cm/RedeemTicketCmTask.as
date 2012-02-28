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
	
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	import protogeni.GeniEvent;
	import protogeni.resources.GeniManager;
	import protogeni.resources.Key;
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualComponent;
	import protogeni.resources.VirtualNode;
	
	/**
	 * FULL only
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestTicketRedeem extends Request
	{
		public var sliver:Sliver;
		private var ticket:String = "";
		private var manifest:String = "";
		
		/**
		 * Redeems a ticket previously given to the user using the ProtoGENI API
		 * 
		 * @param s
		 * 
		 */
		public function RequestTicketRedeem(newSliver:Sliver):void
		{
			super("Redeem ticket @ " + newSliver.manager.Hrn,
				"Updating ticket for sliver on " + newSliver.manager.Hrn + " for slice named " + newSliver.slice.Name,
				CommunicationUtil.redeemTicket);
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Waiting to redeem ticket";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			ticket = sliver.ticket;
			
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			if(sliver.manager.level == GeniManager.LEVEL_MINIMAL)
			{
				LogHandler.appendMessage(new LogMessage(sliver.manager.Url, "Full API not supported", "This manager does not support this API call", LogMessage.ERROR_FAIL));
				return null;
			}
			sliver.message = "Redeeming ticket";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.clearFields();
			
			op.addField("slice_urn", sliver.slice.urn.full);
			op.addField("credentials", [sliver.credential]);
			op.addField("ticket", sliver.ticket);
			var keys:Array = [];
			for each(var key:Key in sliver.slice.creator.keys) {
				keys.push({type:key.type, key:key.value});
			}
			op.addField("keys", keys);
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				sliver.credential = response.value[0];
				
				manifest = response.value[1];
				sliver.parseManifest(new XML(manifest));
				
				var old:Slice = Main.geniHandler.CurrentUser.slices.getByUrn(sliver.slice.urn.full);
				if(old != null)
				{
					var oldSliver:Sliver = old.slivers.getByManager(sliver.manager);
					if(oldSliver != null)
						old.slivers.remove(oldSliver);
					old.slivers.add(sliver);
				}
				
				sliver.message = "Ticket redeemed";
				var startSliver:RequestSliverStart = new RequestSliverStart(sliver);
				startSliver.addAfter = this.addAfter;
				this.addAfter = null;
				return startSliver;
			}
			else
			{
				failed(response.output);
				return new RequestTicketRelease(sliver);
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
				sliver.message = "Failed to redeem ticket"
			for each(var node:VirtualNode in sliver.nodes.collection) {
				node.status = VirtualComponent.STATUS_FAILED;
				node.error = "Sliver had error when redeeming ticket: " + sliver.message;
			}
			
			var managerMsg:String = "";
			if(msg != null && msg.length > 0)
				managerMsg = " Manager reported error: " + msg + ".";
			
			Main.geniHandler.requestHandler.pause();
			Alert.show(
				"Failed to redeem ticket on " + sliver.manager.Hrn+"!" + managerMsg + ". Stop other calls and remove allocated resources?",
				"Failed to redeem ticket",
				Alert.YES|Alert.NO,
				FlexGlobals.topLevelApplication as Sprite,
				function askToContinue(e:CloseEvent):void
				{
					if(e.detail == Alert.YES)
						Main.geniHandler.requestHandler.deleteSlice(sliver.slice);
					else
						Main.geniHandler.requestHandler.start(true);
				},
				null,
				Alert.YES
			);
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):*
		{
			var msg:String = "";
			if(fault != null)
				msg = fault.getFaultString();
			failed(msg);
			return new RequestTicketRelease(sliver);
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_POPULATING);
		}
		
		override public function getSent():String {
			return "******** TICKET ********\n\n" + ticket + "\n\n******** XML-RPC ********\n\n" + op.getSent();
		}
		
		override public function getResponse():String {
			return "******** MANIFEST RSPEC ********\n\n" + manifest + "\n\n******** XML-RPC ********\n\n" + op.getResponse();
		}
	}
}
