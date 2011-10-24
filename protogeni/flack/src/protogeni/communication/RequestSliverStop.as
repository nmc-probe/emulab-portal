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
	import protogeni.resources.GeniManager;
	import protogeni.resources.Sliver;
	
	/**
	 * Stops a sliver using the ProtoGENI API
	 * 
	 * FULL only
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverStop extends Request
	{
		public var sliver:Sliver;
		
		public function RequestSliverStop(newSliver:Sliver):void
		{
			super("Stop sliver @ " + newSliver.manager.Hrn,
				"Stopping sliver on " + newSliver.manager.Hrn + " for slice named " + newSliver.slice.Name,
				CommunicationUtil.stopSliver);
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Stopping";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			if(sliver.manager.level == GeniManager.LEVEL_MINIMAL)
			{
				LogHandler.appendMessage(new LogMessage(sliver.manager.Url, "Full API not supported", "This manager does not support this API call", LogMessage.ERROR_FAIL));
				return null;
			}
			op.clearFields();
			
			op.addField("slice_urn", sliver.slice.urn.full);
			op.addField("credentials", [sliver.slice.credential]);
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				sliver.message = "Stopped";
				return new RequestSliverStatus(sliver);
			}
			else
				failed();
			
			return null;
		}
		
		public function failed():void {
			sliver.changing = false;
			sliver.message = "Stop failed";
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			var msg:String = "";
			if(fault != null)
				msg = fault.getFaultString();
			failed();
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
