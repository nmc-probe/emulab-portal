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
	 * Gets the manifest for a sliver using the ProtoGENI API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverResolve extends Request
	{
		public var sliver:Sliver;
		public var manifest:String = "";
		
		public function RequestSliverResolve(newSliver:Sliver):void
		{
			super("Get manifest @ " + newSliver.manager.Hrn,
				"Resolving sliver on " + newSliver.manager.Hrn + " on slice named " + newSliver.slice.Name,
				CommunicationUtil.resolveResource,
				true,
				true);
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Getting manifest";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.setUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			op.clearFields();
			
			op.addField("urn", sliver.urn.full);
			op.addField("credentials", [sliver.credential]);
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				manifest = response.value.manifest;
				sliver.parseManifest(new XML(manifest));
				if(!sliver.slice.slivers.contains(sliver))
					sliver.slice.slivers.add(sliver);
				
				sliver.message = "Manifest received";
				return new RequestSliverStatus(sliver);
			} else
				failed(response.output);
			
			return null;
		}
		
		public function failed(msg:String = ""):void {
			sliver.changing = false;
			sliver.message = "Getting manifest failed";
			if(msg != null && msg.length > 0)
				sliver.message += ": " + msg;
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
		
		override public function getResponse():String {
			return "******** MANIFEST RSPEC ********\n\n" + manifest + "\n\n******** XML-RPC ********\n\n" + op.getResponse();
		}
	}
}
