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
	
	import protogeni.DateUtil;
	import protogeni.GeniEvent;
	import protogeni.resources.IdnUrn;
	import protogeni.resources.Sliver;
	import protogeni.resources.VirtualNode;
	
	/**
	 * Gets the sliver status using the GENI AM API
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RequestSliverRenewAm extends Request
	{
		public var sliver:Sliver;
		public var expirationDate:Date;
		
		public function RequestSliverRenewAm(newSliver:Sliver, newExpirationDate:Date):void
		{
			super("Renew sliver @ " + newSliver.manager.Hrn,
				"Renewing the sliver on aggregate manager " + newSliver.manager.Hrn + " on slice named " + newSliver.slice.Name,
				CommunicationUtil.sliverStatusAm,
				true,
				true);
			ignoreReturnCode = true;
			expirationDate = newExpirationDate;
			sliver = newSliver;
			sliver.changing = true;
			sliver.message = "Renewing";
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice, GeniEvent.ACTION_STATUS);
			
			op.setExactUrl(sliver.manager.Url);
		}
		
		override public function start():Operation {
			op.clearFields();
			
			op.pushField(sliver.slice.urn.full);
			op.pushField([sliver.slice.credential]);
			op.pushField(DateUtil.toRFC3339(expirationDate));
			
			return op;
		}
		
		override public function complete(code:Number, response:Object):*
		{
			// did it work???
			
			sliver.message = "Renewed";
			return null;
		}
		
		override public function fail(event:ErrorEvent, fault:MethodFault):* {
			sliver.message = "Renew failed";
		}
		
		override public function cleanup():void {
			super.cleanup();
			sliver.changing = false;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
