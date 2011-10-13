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
	
	import protogeni.GeniEvent;
	import protogeni.StringUtil;
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualComponent;
	import protogeni.resources.VirtualNode;
	
	/**
	 * Gets the sliver status using the ProtoGENI API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverStatus extends Request
	{
		public var sliver:Sliver;
		
		public function RequestSliverStatus(newSliver:Sliver):void
		{
			super("Get sliver status @ " + newSliver.manager.Hrn,
				"Getting the sliver status for component manager " + newSliver.manager.Hrn + " on slice named " + newSliver.slice.hrn,
				CommunicationUtil.sliverStatus,
				true,
				true);
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Waiting to check status";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			if(op.delaySeconds == 0)
				sliver.message = "Checking status...";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.clearFields();
			
			op.addField("slice_urn", sliver.slice.urn.full);
			op.addField("credentials", new Array(sliver.slice.credential));
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			var old:Slice;
			var oldSliver:Sliver;
			var request:Request = null;
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				sliver.state = response.value.state;
				if(sliver.state == Sliver.STATE_STOPPED)
					sliver.status = Sliver.STATUS_STOPPED;
				else
					sliver.status = response.value.status;
				for(var sliverId:String in response.value.details)
				{
					var sliverDetails:Object = response.value.details[sliverId];
					
					var virtualComponent:VirtualComponent = sliver.getBySliverId(sliverId);
					if(virtualComponent != null)
					{
						virtualComponent.state = sliverDetails.state;
						if(virtualComponent.state == Sliver.STATE_STOPPED)
							virtualComponent.status = Sliver.STATUS_STOPPED;
						else
							virtualComponent.status = sliverDetails.status;
						virtualComponent.error = sliverDetails.error;
					}
				}
				sliver.changing = !sliver.StatusFinalized;
				sliver.message = StringUtil.firstToUpper(sliver.status);
				if(sliver.changing) {
					sliver.message = "Status is " + sliver.message + "...";
					request = this;
					request.op.delaySeconds = Math.min(60, this.op.delaySeconds + 15);
				} else {
					sliver.message += "!";
				}
				
				old = Main.geniHandler.CurrentUser.slices.getByUrn(sliver.slice.urn.full);
				if(old != null)
				{
					oldSliver = old.slivers.getByManager(sliver.manager);
					if(oldSliver != null)
						oldSliver.copyStatusFrom(sliver);
				}
			}
			// Slice was deleted
			else if(code == CommunicationUtil.GENIRESPONSE_SEARCHFAILED) {
				sliver.removeOutsideReferences();
				if(sliver.slice.slivers.contains(sliver))
					sliver.slice.slivers.remove(sliver);
				old = Main.geniHandler.CurrentUser.slices.getByUrn(sliver.slice.urn.full);
				if(old != null)
				{
					oldSliver = old.slivers.getByUrn(sliver.urn.full);
					if(oldSliver != null) {
						oldSliver.removeOutsideReferences();
						old.slivers.remove(old.slivers.getByUrn(sliver.urn.full));
					}
				}
				sliver.changing = false;
				sliver.message = "Status was deleted";
			}
			
			return request;
		}
		
		public function failed(msg:String = ""):void {
			sliver.changing = false;
			sliver.message = "Checking status failed";
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			var msg:String = "";
			if(fault != null)
				msg = fault.getFaultString();
			failed(msg);
			return null
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
		}
	}
}
