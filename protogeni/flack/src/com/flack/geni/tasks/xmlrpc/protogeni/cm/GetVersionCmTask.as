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

package com.flack.geni.tasks.xmlrpc.protogeni.cm
{
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.resources.docs.RspecVersionCollection;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.TaskError;
	
	/**
	 * Gets version information from the manager.
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetVersionCmTask extends ProtogeniXmlrpcTask
	{
		public var manager:GeniManager;
		
		/**
		 * 
		 * @param newManager Manager to get version info for
		 * 
		 */
		public function GetVersionCmTask(newManager:GeniManager)
		{
			super(
				newManager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_GETVERSION,
				"Get version @ " + newManager.hrn,
				"Gets the version information of the component manager named " + newManager.hrn,
				"Get Version"
			);
			maxTries = 1;
			promptAfterMaxTries = false;
			newManager.Status = FlackManager.STATUS_INPROGRESS;
			relatedTo.push(newManager);
			manager = newManager;
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				manager.api.version = Number(data.api);
				manager.api.level = int(data.level);
				
				manager.inputRspecVersions = new RspecVersionCollection();
				manager.outputRspecVersions = new RspecVersionCollection();
				
				// request RSPEC versions
				for each(var inputVersion:Number in data.input_rspec)
				{
					if(inputVersion)
					{
						var newInputVersion:RspecVersion =
							new RspecVersion(
								inputVersion < 3 ? RspecVersion.TYPE_PROTOGENI : RspecVersion.TYPE_GENI,
								inputVersion
							);
						manager.inputRspecVersions.add(newInputVersion);
					}
				}
				
				// ad RSPEC versions
				var outputRspecDefaultVersionNumber:Number = Number(data.output_rspec);
				if(data.ad_rspec != null)
				{
					for each(var outputVersion:Number in data.ad_rspec)
					{
						if(outputVersion)
						{
							var newOutputVersion:RspecVersion =
								new RspecVersion(
									outputVersion < 3 ? RspecVersion.TYPE_PROTOGENI : RspecVersion.TYPE_GENI,
									outputVersion
								);
							if(outputRspecDefaultVersionNumber == outputVersion)
								manager.outputRspecVersion = newOutputVersion;
							manager.outputRspecVersions.add(newOutputVersion);
						}
					}
				}
				else
				{
					manager.outputRspecVersions.add(
						new RspecVersion(
							outputRspecDefaultVersionNumber < 3 ? RspecVersion.TYPE_PROTOGENI : RspecVersion.TYPE_GENI,
							outputRspecDefaultVersionNumber
						)
					);
					manager.outputRspecVersion = manager.outputRspecVersions.collection[0];
				}
				
				
				// Set defaults
				if(manager.outputRspecVersion == null)
					manager.outputRspecVersion = manager.outputRspecVersions.MaxVersion;
				manager.inputRspecVersion = manager.inputRspecVersions.MaxVersion;
				
				addMessage(
					"Version found",
					"Input: "+manager.inputRspecVersion.toString()+"\nOutput:" + manager.outputRspecVersion.toString(),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_MANAGER,
					manager
				);
				
				parent.add(new DiscoverResourcesCmTask(manager));
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
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
			manager.Status = FlackManager.STATUS_FAILED;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_MANAGER,
				manager,
				FlackEvent.ACTION_STATUS
			);
		}
	}
}