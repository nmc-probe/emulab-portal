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
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.tasks.process.ParseAdvertisementTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.tasks.http.HttpTask;
	import com.flack.shared.utils.CompressUtil;
	
	/**
	 * Downloads a cached advertisement RSPEC for the given manager
	 * 
	 * @author mstrum
	 * 
	 */
	public class PublicListResourcesTask extends HttpTask
	{
		public var manager:GeniManager;
		
		/**
		 * 
		 * @param newManager Manager to get public resources for
		 * 
		 */
		public function PublicListResourcesTask(newManager:GeniManager)
		{
			super(
				newManager.url,
				"Download advertisement for " + newManager.hrn,
				"Downloads the advertisement at " + newManager.url
			);
			manager = newManager;
			
			manager.Status = FlackManager.STATUS_INPROGRESS;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				manager,
				FlackEvent.ACTION_STATUS
			);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Might be compressed
			if(data.charAt(0) != '<')
			{
				data = CompressUtil.uncompress(data);
				
				addMessage(
					"Received advertisement",
					data,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
			}
			
			manager.advertisement = new Rspec(XML(data));
			parent.add(new ParseAdvertisementTask(manager));
			
			super.afterComplete(addCompletedMessage);
		}
		
		override protected function afterError(taskError:TaskError):void
		{
			manager.Status = FlackManager.STATUS_FAILED;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				manager,
				FlackEvent.ACTION_STATUS
			);
			
			super.afterError(taskError);
		}
		
		override protected function runCancel():void
		{
			manager.Status = FlackManager.STATUS_UNKOWN;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				manager,
				FlackEvent.ACTION_STATUS
			);
		}
	}
}