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
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.resources.docs.RspecVersionCollection;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Gets version info from manager then adds task to get resources
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetVersionTask extends AmXmlrpcTask
	{
		public var manager:GeniManager;
		
		/**
		 * 
		 * @param newManager Manager to get the version info for
		 * 
		 */
		public function GetVersionTask(newManager:GeniManager)
		{
			super(
				newManager.api.url,
				AmXmlrpcTask.METHOD_GETVERSION,
				NaN,
				"Get version @ " + newManager.hrn,
				"Getting the version information of the aggregate manager for " + newManager.hrn,
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
				manager.api.version = Number(data.geni_api);
				
				manager.apis = new Vector.<ApiDetails>();
				if(data.geni_api_versions != null)
				{
					var highestSuppportedVersion:ApiDetails = manager.api;
					for(var supportedApiVersion:String in data.geni_api_versions)
					{
						var supportedApiUrl:String = data.geni_api_versions[supportedApiVersion];
						var supportedApi:ApiDetails = 
							new ApiDetails(
								manager.api.type,
								Number(supportedApiVersion),
								supportedApiUrl
							);
						if(supportedApi.version <= 2 && supportedApi.version > highestSuppportedVersion.version)
							highestSuppportedVersion = supportedApi;
						manager.apis.push(supportedApi);
					}
					if(highestSuppportedVersion.version > manager.api.version)
					{
						// Set API to higher value and run GetVersion there
						manager.api = highestSuppportedVersion;
						
						parent.add(new GetVersionTask(manager));
						
						super.afterComplete(addCompletedMessage);
						
						return;
					}
				}
				
				manager.inputRspecVersions = new RspecVersionCollection();
				manager.outputRspecVersions = new RspecVersionCollection();
				
				// Request RSPEC versions
				var requestRspecVersions:Array = null;
				switch(manager.api.version)
				{
					case 1:
						requestRspecVersions = data.request_rspec_versions;
						break;
					case 2:
					default:
						requestRspecVersions = data.geni_request_rspec_versions;
				}
				if(requestRspecVersions != null)
				{
					for each(var requestRspecVersion:Object in requestRspecVersions)
					{
						var requestVersion:RspecVersion = 
							new RspecVersion(
								String(requestRspecVersion.type).toLowerCase(),
								Number(requestRspecVersion.version)
							);
						manager.inputRspecVersions.add(requestVersion);
					}
				}
				
				// Advertisement RSPEC versions
				var adRspecVersions:Array = null;
				switch(manager.api.version)
				{
					case 1:
						adRspecVersions = data.ad_rspec_versions;
						break;
					case 2:
					default:
						adRspecVersions = data.geni_ad_rspec_versions;
				}
				if(adRspecVersions != null)
				{
					for each(var adRspecVersion:Object in adRspecVersions)
					{
						var adVersion:RspecVersion =
							new RspecVersion(
								String(adRspecVersion.type).toLowerCase(),
								Number(adRspecVersion.version)
							);
						manager.outputRspecVersions.add(adVersion);
					}
				}
				
				// Make sure aggregate uses compatible rspec
				if(manager.inputRspecVersions.UsableRspecVersions.length > 0 && manager.outputRspecVersions.UsableRspecVersions.length > 0)
				{
					manager.outputRspecVersion = manager.outputRspecVersions.UsableRspecVersions.MaxVersion;
					manager.inputRspecVersion = manager.inputRspecVersions.UsableRspecVersions.MaxVersion;
					
					addMessage(
						"Compatible",
						"Input: "+manager.inputRspecVersion.toString()+"\nOutput:" + manager.outputRspecVersion.toString(),
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_MANAGER,
						manager
					);
					
					parent.add(new ListManagerResourcesTask(manager));
					
					super.afterComplete(addCompletedMessage);
				}
				else
				{
					manager.errorType = FlackManager.FAIL_NOTSUPPORTED;
					afterError(
						new TaskError(
							"ProtoGENI RSPEC not supported",
							TaskError.CODE_PROBLEM
						)
					);
				}
						
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