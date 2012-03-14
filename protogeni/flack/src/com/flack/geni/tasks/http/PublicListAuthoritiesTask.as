/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
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

package com.flack.geni.tasks.http
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.sites.authorities.ProtogeniSliceAuthority;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.http.HttpTask;
	import com.flack.shared.tasks.http.JsHttpTask;
	
	import flash.system.Security;
	
	/**
	 * Downloads a public list of ProtoGENI slice authorities
	 * 
	 * @author mstrum
	 * 
	 */
	public class PublicListAuthoritiesTask extends HttpTask
	{
		public function PublicListAuthoritiesTask()
		{
			super(
				"https://www.emulab.net/protogeni/pub/salist.txt", //authorities
				"Download authority list",
				"Gets list of slice authorities"
			);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			//GeniMain.geniUniverse.authorities = new GeniAuthorityCollection();
			
			var sliceAuthorityLines:Array = data.split(/[\n\r]+/);
			for each(var sliceAuthorityLine:String in sliceAuthorityLines)
			{
				if(sliceAuthorityLine.length == 0)
					continue;
				var sliceAuthorityLineParts:Array = sliceAuthorityLine.split(" ");
				var sliceAuthority:ProtogeniSliceAuthority =
					new ProtogeniSliceAuthority(
						sliceAuthorityLineParts[0],
						sliceAuthorityLineParts[1],
						true
					);
				sliceAuthority.url = sliceAuthority.url.replace(":12369", "");
				if(GeniMain.geniUniverse.authorities.getByUrl(sliceAuthority.url) == null)
					GeniMain.geniUniverse.authorities.add(sliceAuthority);
				addMessage(
					"Added authority",
					sliceAuthority.toString()
				);
			}
			
			addMessage(
				"Added "+GeniMain.geniUniverse.authorities.length+" authorities",
				"Added "+GeniMain.geniUniverse.authorities.length+" authorities",
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_AUTHORITIES,
				null,
				FlackEvent.ACTION_POPULATED
			);
			
			super.afterComplete(addCompletedMessage);
		}
	}
}