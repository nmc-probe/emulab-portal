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
	import protogeni.resources.Key;
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualComponent;
	import protogeni.resources.VirtualNode;
	
	/**
	 * Allocates resources to a sliver using the GENI AM API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverCreateAm extends Request
	{
		public var sliver:Sliver;
		public var request:String = "";
		public var manifest:String = "";
		
		public function RequestSliverCreateAm(s:Sliver, useRspec:XML = null):void
		{
			super("SliverCreateAM",
				"Creating sliver on " + s.manager.Hrn + " for slice named " + s.slice.hrn,
				CommunicationUtil.createSliverAm,
				true);
			ignoreReturnCode = true;
			sliver = s;
			sliver.clearState();
			sliver.changing = true;
			sliver.manifest = null;
			sliver.message = "Creating";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			op.timeout = 360;
			
			// Build up the args
			op.pushField(sliver.slice.urn.full);
			op.pushField([sliver.slice.credential]);
			if(useRspec != null)
				request = useRspec.toXMLString();
			else
				request = sliver.slice.slivers.Combined.getRequestRspec(true).toXMLString();
			op.pushField(request);
			var userKeys:Array = [];
			for each(var key:Key in sliver.slice.creator.keys) {
				userKeys.push(key.value);
			}
			op.pushField([{urn:Main.geniHandler.CurrentUser.urn.full, keys:userKeys}]);
			op.setExactUrl(sliver.manager.Url);
		}
		
		override public function complete(code:Number, response:Object):*
		{
			try
			{
				manifest = String(response);
				sliver.manifest = new XML(manifest);
			}
			catch(e:Error)
			{
				failed();
				return;
			}
			
			try
			{
				sliver.parseManifest();
				
				var old:Slice = Main.geniHandler.CurrentUser.slices.getByUrn(sliver.slice.urn.full);
				if(old != null)
				{
					if(old.slivers.getByUrn(sliver.urn.full) != null)
						old.slivers.remove(old.slivers.getByUrn(sliver.urn.full));
					old.slivers.add(sliver);
				}
				
				sliver.message = "Created";
				return new RequestSliverStatusAm(sliver);
			}
			catch(e:Error)
			{
				LogHandler.appendMessage(new LogMessage(sliver.manager.Url,
					"SliverCreateAM",
					"Error parsing RSPEC\n\n" + e.toString(),
					true,
					LogMessage.TYPE_END));
				failed();
			}
			
			return null;
		}
		
		private function failed(msg:String = ""):void {
			sliver.status = Sliver.STATUS_FAILED;
			sliver.state = Sliver.STATE_NA;
			sliver.changing = false;
			
			sliver.message = "Failed to create";
			
			for each(var node:VirtualNode in sliver.nodes.collection) {
				node.status = VirtualComponent.STATUS_FAILED;
				node.error = "Sliver had error when creating: " + sliver.message;
			}
			
			Alert.show("Failed to create sliver on " + sliver.manager.Hrn+"!" , "Failed to create sliver");
			
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
			failed();
			return super.fail(event, fault);
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_POPULATING);
		}
		
		override public function getSent():String {
			return "******** REQUEST RSPEC ********\n\n" + request + "\n\n******** XML-RPC ********" + op.getSent();
		}
		
		override public function getResponse():String {
			return "******** MANIFEST RSPEC ********\n\n" + manifest + "\n\n******** XML-RPC ********" + op.getResponse();
		}
	}
}
