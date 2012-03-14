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

package com.flack.geni.tasks.xmlrpc.protogeni.ch
{
	import com.flack.geni.GeniCache;
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.sites.managers.PlanetlabAggregateManager;
	import com.flack.geni.resources.sites.managers.ProtogeniComponentManager;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Gets the list and information for the component managers listed at a clearinghouse
	 * 
	 * @author mstrum
	 * 
	 */
	public class ListComponentsChTask extends ProtogeniXmlrpcTask
	{
		public var user:GeniUser;
		
		/**
		 * 
		 * @param newUser User making the call, needed for this call
		 * 
		 */
		public function ListComponentsChTask(newUser:GeniUser)
		{
			super(
				GeniMain.geniUniverse.clearinghouse.url,
				ProtogeniXmlrpcTask.MODULE_CH,
				ProtogeniXmlrpcTask.METHOD_LISTCOMPONENTS,
				"List managers",
				"Gets the list and information for the component managers listed at a clearinghouse"
			);
			user = newUser;
		}
		
		override protected function createFields():void
		{
			addNamedField("credential", user.credential.Raw);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				GeniMain.geniUniverse.managers = new GeniManagerCollection();
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_MANAGERS,
					null,
					FlackEvent.ACTION_REMOVED
				);
				
				for each(var obj:Object in data)
				{
					try
					{
						var newManager:GeniManager = null;
						var url:String = obj.url;
						url = url.replace(":12369", "");
						var newId:IdnUrn = new IdnUrn(obj.urn);
						
						// ProtoGENI Component Manager
						if(newId.name == ProtogeniXmlrpcTask.MODULE_CM)
						{
							var protogeniManager:ProtogeniComponentManager = new ProtogeniComponentManager(newId.full);
							protogeniManager.hrn = obj.hrn;
							protogeniManager.url = url.substr(0, url.length-3);
							if(protogeniManager.hrn == "ukgeni.cm" || protogeniManager.hrn == "utahemulab.cm")
								protogeniManager.supportsIon = true;
							if(protogeniManager.hrn == "wail.cm" || protogeniManager.hrn == "utahemulab.cm")
								protogeniManager.supportsGpeni = true;
							if(protogeniManager.hrn == "utahemulab.cm")
								protogeniManager.supportsFirewallNodes = true;
							if(protogeniManager.hrn == "shadowgeni.cm" || protogeniManager.hrn == "mygeni.cm")
							{
								protogeniManager.supportsDelayNodes = false;
								protogeniManager.supportsUnboundRawNodes = false;
								protogeniManager.supportsUnboundVmNodes = false;
							}
							newManager = protogeniManager;
						}
						else if(newId.name == ProtogeniXmlrpcTask.MODULE_SA)
						{
							var planetLabManager:PlanetlabAggregateManager = new PlanetlabAggregateManager(newId.full);
							planetLabManager.hrn = obj.hrn;
							//url = "https://sfa-devel.planet-lab.org:12346";//"https://sfa-devel.planet-lab.org:12346";
							planetLabManager.url = StringUtil.makeSureEndsWith(url, "/"); // needs this for forge...
							planetLabManager.registryUrl = planetLabManager.url.replace("12346", "12345");
							newManager = planetLabManager;
						}
						else
						{
							var otherManager:GeniManager = new GeniManager(FlackManager.TYPE_OTHER, ApiDetails.API_GENIAM, newId.full);
							otherManager.hrn = obj.hrn;
							otherManager.url = StringUtil.makeSureEndsWith(url, "/");
							newManager = otherManager;
						}
						newManager.id = newId;
						newManager.api.url = newManager.url;
						
						GeniMain.geniUniverse.managers.add(newManager);
						
						addMessage(
							"Added manager",
							newManager.toString(),
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						
						SharedMain.sharedDispatcher.dispatchChanged(
							FlackEvent.CHANGED_MANAGER,
							newManager,
							FlackEvent.ACTION_CREATED
						);
						
					}
					catch(e:Error)
					{
						addMessage(
							"Error adding",
							"Couldn't add manager from list:\n" + obj.toString(),
							LogMessage.LEVEL_WARNING,
							LogMessage.IMPORTANCE_HIGH
						);
					}
				}
				
				addMessage(
					"Added " + GeniMain.geniUniverse.managers.length + " manager(s)",
					"Added " + GeniMain.geniUniverse.managers.length + " manager(s)",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				var manuallyAddedManagers:GeniManagerCollection = GeniCache.getManualManagers();
				for each(var cachedManager:GeniManager in manuallyAddedManagers.collection)
				{
					if(GeniMain.geniUniverse.managers.getById(cachedManager.id.full) == null)
					{
						GeniMain.geniUniverse.managers.add(cachedManager);
						
						addMessage(
							"Added cached manager",
							cachedManager.toString(),
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						
						SharedMain.sharedDispatcher.dispatchChanged(
							FlackEvent.CHANGED_MANAGER,
							cachedManager,
							FlackEvent.ACTION_CREATED
						);
					}
				}
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_MANAGERS,
					null,
					FlackEvent.ACTION_POPULATED
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}