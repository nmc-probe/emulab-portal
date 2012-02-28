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
			super("Create sliver @ " + s.manager.Hrn,
				"Creating sliver on aggregate manager " + s.manager.Hrn + " for slice named " + s.slice.Name,
				CommunicationUtil.createSliverAm,
				true);
			ignoreReturnCode = true;
			sliver = s;
			sliver.clearState();
			sliver.changing = true;
			sliver.manifest = null;
			sliver.message = "Waiting to create";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			op.timeout = 360;
			
			if(useRspec != null)
				request = useRspec.toXMLString();
			else
				request = sliver.slice.slivers.Combined.getRequestRspec(true).toXMLString();
			
			op.setExactUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			sliver.message = "Creating";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			op.clearFields();
			
			op.pushField(sliver.slice.urn.full);
			op.pushField([sliver.slice.credential]);
			op.pushField(request);
			var userKeys:Array = [];
			for each(var key:Key in sliver.slice.creator.keys)
				userKeys.push(key.value);
			op.pushField([{urn:Main.geniHandler.CurrentUser.urn.full, keys:userKeys}]);
			
			return op;
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
					LogMessage.ERROR_FAIL,
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
			
			var managerMsg:String = "";
			if(msg != null && msg.length > 0)
				managerMsg = " Manager reported error: " + msg + ".";
			
			Main.geniHandler.requestHandler.pause();
			Alert.show(
				"Failed to create sliver on " + sliver.manager.Hrn+"!" + managerMsg + ". Stop other calls and remove allocated resources?",
				"Failed to create sliver",
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
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			failed();
			return super.fail(event, fault);
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_POPULATING);
		}
		
		override public function getSent():String {
			return "******** REQUEST RSPEC ********\n\n" + request + "\n\n******** XML-RPC ********\n\n" + op.getSent();
		}
		
		override public function getResponse():String {
			return "******** MANIFEST RSPEC ********\n\n" + manifest + "\n\n******** XML-RPC ********\n\n" + op.getResponse();
		}
	}
}
