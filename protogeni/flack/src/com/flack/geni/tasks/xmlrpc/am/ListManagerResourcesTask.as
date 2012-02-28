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

package com.flack.geni.tasks.xmlrpc.am
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.tasks.process.ParseAdvertisementTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.CompressUtil;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Lists all of the manager's resources.  Adds a seperate task to the parent to parse the advertisement.
	 * 
	 * @author mstrum
	 * 
	 */
	public class ListManagerResourcesTask extends AmXmlrpcTask
	{
		public var manager:GeniManager;
		
		/**
		 * 
		 * @param newManager Manager to list resources for
		 * 
		 */
		public function ListManagerResourcesTask(newManager:GeniManager)
		{
			super(
				newManager.api.url,
				AmXmlrpcTask.METHOD_LISTRESOURCES,
				newManager.api.version,
				"List resources @ " + newManager.hrn,
				"Listing resources for aggregate manager " + newManager.hrn,
				"List Resources"
			);
			relatedTo.push(newManager);
			manager = newManager;
		}
		
		override protected function createFields():void
		{
			addOrderedField([GeniMain.geniUniverse.user.credential.Raw]);
			
			var options:Object = 
				{
					geni_available: false,
					geni_compressed: true
				};
			var rspecVersion:Object = 
				{
					type:manager.outputRspecVersion.type,
					version:manager.outputRspecVersion.version.toString()
				};
			if(apiVersion < 2)
				options.rspec_version = rspecVersion;
			else
				options.geni_rspec_version = rspecVersion;
			
			addOrderedField(options);	
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Sanity check for AM API 2+
			if(apiVersion > 1)
			{
				if(genicode != AmXmlrpcTask.GENICODE_SUCCESS)
				{
					faultOnSuccess();
					return;
				}
			}
			
			try
			{
				var uncompressedRspec:String = CompressUtil.uncompress(data);
				
				addMessage(
					"Received advertisement",
					uncompressedRspec,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				manager.advertisement = new Rspec(uncompressedRspec);
				parent.add(new ParseAdvertisementTask(manager));
				
				super.afterComplete(addCompletedMessage);
				
			}
			catch(e:Error)
			{
				afterError(
					new TaskError(
						StringUtil.errorToString(e),
						TaskError.CODE_UNEXPECTED,
						e
					)
				);
			}
		}
		
		override protected function afterError(taskError:TaskError):void
		{
			manager.Status = FlackManager.STATUS_FAILED;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				manager
			);
			
			super.afterError(taskError);
		}
		
		override protected function runCancel():void
		{
			manager.Status = FlackManager.STATUS_UNKOWN;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				manager
			);
		}
	}
}