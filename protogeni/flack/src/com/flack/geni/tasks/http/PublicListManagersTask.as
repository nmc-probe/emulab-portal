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
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.sites.managers.ProtogeniComponentManager;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.http.HttpTask;
	import com.flack.shared.tasks.http.JsHttpTask;
	import com.flack.shared.utils.NetUtil;
	
	import flash.system.Security;
	
	/**
	 * Downloads a list of cached advertisements
	 * 
	 * @author mstrum
	 * 
	 */
	public final class PublicListManagersTask extends HttpTask
	{
		public function PublicListManagersTask()
		{
			super(
				"https://www.emulab.net/protogeni/pub/list.txt", // advertisements
				"Download advertisement list",
				"Gets the list of advertisements"
			);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			GeniMain.geniUniverse.managers = new GeniManagerCollection();
			
			var lines:Array = (data as String).split(/[\n\r]+/); // no +?
			for each(var line:String in lines)
			{
				if(line.length == 0)
					continue;
				var newManager:ProtogeniComponentManager = new ProtogeniComponentManager(line);
				newManager.url = url.substring(0, url.lastIndexOf('/')+1) + line;
				newManager.hrn = newManager.id.authority;
				GeniMain.geniUniverse.managers.add(newManager);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_MANAGER,
					newManager,
					FlackEvent.ACTION_CREATED
				);
				addMessage(
					"Added manager",
					newManager.toString())
				;
			}
			
			addMessage(
				"Added "+GeniMain.geniUniverse.managers.length+" managers",
				"Added "+GeniMain.geniUniverse.managers.length+" managers",
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGERS,
				null,
				FlackEvent.ACTION_POPULATED
			);
			
			super.afterComplete(addCompletedMessage);
		}
	}
}