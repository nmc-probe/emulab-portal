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
	import protogeni.resources.IdnUrn;
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualNode;
	
	/**
	 * Gets the sliver status using the GENI AM API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverStatusAm extends Request
	{
		public var sliver:Sliver;
		
		public function RequestSliverStatusAm(newSliver:Sliver):void
		{
			super("Get sliver status @ " + newSliver.manager.Hrn,
				"Getting the sliver status for aggregate manager " + newSliver.manager.Hrn + " on slice named " + newSliver.slice.Name,
				CommunicationUtil.sliverStatusAm,
				true,
				true);
			ignoreReturnCode = true;
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Waiting to check status";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.setExactUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			if(op.delaySeconds == 0)
				sliver.message = "Checking status...";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			op.clearFields();
			
			op.pushField(sliver.slice.urn.full);
			op.pushField([sliver.slice.credential]);
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			var request:Request = null;
			try
			{
				sliver.status = response.geni_status;
				sliver.urn = new IdnUrn(response.geni_urn);
				for each(var nodeObject:Object in response.geni_resources)
				{
					var vn:VirtualNode = sliver.nodes.getBySliverId(nodeObject.geni_urn);
					if(vn == null)
						vn = sliver.nodes.getByComponentId(nodeObject.geni_urn);
					if(vn != null)
					{
						vn.status = nodeObject.geni_status;
						vn.error = nodeObject.geni_error;
					}
				}
				
				sliver.changing = !sliver.StatusFinalized;
				sliver.message = StringUtil.firstToUpper(sliver.status) + "!";
				if(sliver.changing) {
					sliver.message = "Status is " + sliver.message + "...";
					request = this;
					request.op.delaySeconds = Math.min(60, this.op.delaySeconds + 15);
				}
			}
			catch(e:Error)
			{
				sliver.changing = false;
			}
			
			return request;
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
