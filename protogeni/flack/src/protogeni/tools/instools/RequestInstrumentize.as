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

package protogeni.tools.instools
{
	import protogeni.communication.CommunicationUtil;
	import protogeni.communication.Request;
	
	import mx.controls.Alert;
	import com.adobe.crypto.SHA1;
	
	import protogeni.Util;
	import protogeni.resources.Sliver;
	
	/**
	 * Instruments a sliver
	 * 
	 * @author jreed
	 * 
	 */
	public final class RequestInstrumentize extends Request
	{
		public var sliver:Sliver;
		public function RequestInstrumentize(s:Sliver):void
		{
			super("InstoolsInstrumentize",
				"Instrumentizing the experiment.",
				Instools.instoolsInstrumentize,
				true,
				true);
			op.setUrl(s.manager.Url);
			sliver = s;
			sliver.changing = true;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			
			op.addField("urn", sliver.slice.urn.full);
			//we currently do not support virtual nodes as MCs
			
			//var passwd:String = Util.rc4encrypt("secretkey",Main.geniHandler.CurrentUser.passwd);
			//passwd = encodeURI(passwd);
			var passwd:String;
			passwd = SHA1.hash(Main.geniHandler.CurrentUser.passwd);
			
			op.addField("password", passwd);
			op.addField("INSTOOLS_VERSION",Instools.devel_version[sliver.manager.Urn.full.toString()]);
			op.addField("credentials", [sliver.slice.credential]);
			//op.setUrl("https://www.uky.emulab.net/protogeni/xmlrpc");
		}
		
		override public function complete(code:Number, response:Object):*
		{
			//do nothing
			
			return null;
		}
		
		override public function cleanup():void {
			super.cleanup();
			sliver.changing = false;
			Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
		}
	}
}
