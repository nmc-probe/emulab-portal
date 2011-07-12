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
	import protogeni.resources.Sliver;
	
	/**
	 * Restarts a sliver using the ProtoGENI API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverRestart extends Request
	{
		public var sliver:Sliver;
		
		public function RequestSliverRestart(s:Sliver):void
		{
			super("SliverRestart",
				"Restarting sliver on " + s.manager.Hrn + " for slice named " + s.slice.hrn,
				CommunicationUtil.restartSliver);
			sliver = s;
			sliver.changing = true;
			sliver.message = "Restarting";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			// Build up the args
			op.addField("slice_urn", sliver.slice.urn.full);
			op.addField("credentials", [sliver.slice.credential]);
			op.setUrl(sliver.manager.Url);
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				sliver.message = "Restarted";
				return new RequestSliverStatus(sliver);
			}
			else
				failed();
			
			return null;
		}
		
		public function failed(msg:String = ""):void {
			sliver.changing = false;
			sliver.message = "Restart failed";
			if(msg != null && msg.length > 0)
				sliver.message += ": " + msg;
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			failed(fault.getFaultString());
			return super.fail(event, fault);
		}
		
		override public function cleanup():void {
			super.cleanup();
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
