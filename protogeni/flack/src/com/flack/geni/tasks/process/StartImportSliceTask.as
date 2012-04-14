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

package com.flack.geni.tasks.process
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.RspecUtil;
	import com.flack.geni.display.ChooseManagerWindow;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.StringUtil;
	
	import flash.system.System;
	
	import mx.controls.Alert;
	
	/**
	 * Does preliminary checks for importing and adds parse tasks to the parent task
	 * 
	 * @author mstrum
	 * 
	 */
	public final class StartImportSliceTask extends Task
	{
		public var slice:Slice;
		public var rspecString:String;
		public var checkRspec:XML;
		public var defaultManager:GeniManager;
		public var overwrite:Boolean;
		
		/**
		 * 
		 * @param importSlice Slice to import into
		 * @param importRspec RSPEC to import into the slice
		 * @param importManager Manager to default to if a manager isn't listed
		 * @param allowOverwrite Allow the import to happen into an already allocated slice
		 * 
		 */
		public function StartImportSliceTask(importSlice:Slice,
											 importRspec:String,
											 importManager:GeniManager = null,
											 allowOverwrite:Boolean = false)
		{
			super(
				"Prepare import",
				"Prepares the slice and RSPEC for the import",
				"",
				null,
				0,
				0,
				false,
				[importSlice]
			);
			slice = importSlice;
			rspecString = importRspec;
			defaultManager = importManager;
			overwrite = allowOverwrite;
		}
		
		override protected function runStart():void
		{
			var msg:String;
			if(slice.slivers.length > 0 && !overwrite)
			{
				msg = "The slice has already been allocated.";
				Alert.show(msg);
				afterError(
					new TaskError(
						msg,
						TaskError.CODE_PROBLEM
					)
				);
				return;
			}
			if(!overwrite && (slice.links.length > 0 || slice.nodes.length > 0))
			{
				msg = "The slice already has resources waiting to be allocated.";
				Alert.show(msg);
				afterError(
					new TaskError(
						msg,
						TaskError.CODE_PROBLEM
					)
				);
				return;
			}
			
			try
			{
				checkRspec = new XML(rspecString);
			}
			catch(e:Error)
			{
				msg = "The document was either not XML or is not formatted correctly!";
				Alert.show(msg);
				afterError(
					new TaskError(
						msg,
						TaskError.CODE_PROBLEM,
						e
					)
				);
				return;
			}
			
			var defaultNamespace:Namespace = checkRspec.namespace();
			var detectedRspecVersion:Number;
			switch(defaultNamespace.uri)
			{
				case RspecUtil.rspec01Namespace:
					detectedRspecVersion = 0.1;
					break;
				case RspecUtil.rspec02Namespace:
				case RspecUtil.rspec02MalformedNamespace:
					detectedRspecVersion = 0.2;
					break;
				case RspecUtil.rspec2Namespace:
					detectedRspecVersion = 2;
					break;
				case RspecUtil.rspec3Namespace:
					detectedRspecVersion = 3;
					break;
				default:
					msg = "Please use a compatible RSPEC. The namespace '"+defaultNamespace.uri+"' was not recognized";
					Alert.show(msg);
					afterError(
						new TaskError(
							msg,
							TaskError.CODE_PROBLEM
						)
					);
					return;
			}
			
			for each(var nodeXml:XML in checkRspec.defaultNamespace::node)
			{
				var managerUrn:String;
				if(detectedRspecVersion < 1)
				{
					if(nodeXml.@component_manager_urn.length() == 1)
						managerUrn = nodeXml.@component_manager_urn;
					else
						managerUrn = nodeXml.@component_manager_uuid;
				}
				else
					managerUrn = nodeXml.@component_manager_id;
				if(managerUrn.length > 0)
				{
					var detectedManager:GeniManager = GeniMain.geniUniverse.managers.getById(managerUrn);
					if(detectedManager == null)
					{
						msg = "Unkown manager referenced: " + managerUrn;
						Alert.show(msg);
						afterError(
							new TaskError(
								msg,
								TaskError.CODE_PROBLEM
							)
						);
						return;
					}
					else if(detectedManager.Status != FlackManager.STATUS_VALID)
					{
						msg = "Known manager referenced (" + managerUrn + "), but manager didn't load successfully. Please restart Flack.";
						Alert.show(msg);
						afterError(
							new TaskError(
								msg,
								TaskError.CODE_PROBLEM
							)
						);
						return;
					}
				}
				else if(defaultManager == null)
				{
					var askForManager:ChooseManagerWindow = new ChooseManagerWindow();
					askForManager.success = preSelectedManager;
					askForManager.showWindow();
					Alert.show("There were resources detected without a manager selected, please select which manager you would like to use.");
					return;
				}
			}
			
			doImport();
		}
		
		public function preSelectedManager(newManager:GeniManager):void
		{
			if(newManager == null)
			{
				var msg:String = "No default manager selected for resources without assigned manager";
				Alert.show(msg);
				afterError(
					new TaskError(
						msg,
						TaskError.CODE_PROBLEM
					)
				);
			}
			else
			{
				defaultManager = newManager;
				doImport();
			}
		}
		
		public function doImport():void
		{
			var importRspec:Rspec = new Rspec();
			importRspec.type = Rspec.TYPE_REQUEST;
			var defaultNamespace:Namespace = checkRspec.namespace();
			var managersWithResources:Vector.<GeniManager> = new Vector.<GeniManager>();
			switch(defaultNamespace.uri)
			{
				case RspecUtil.rspec01Namespace:
					importRspec.info = new RspecVersion(RspecVersion.TYPE_PROTOGENI, 0.1);
					break;
				case RspecUtil.rspec02Namespace:
				case RspecUtil.rspec02MalformedNamespace:
					importRspec.info = new RspecVersion(RspecVersion.TYPE_PROTOGENI, 0.2);
					break;
				case RspecUtil.rspec2Namespace:
					importRspec.info = new RspecVersion(RspecVersion.TYPE_PROTOGENI, 2);
					break;
				case RspecUtil.rspec3Namespace:
					importRspec.info = new RspecVersion(RspecVersion.TYPE_GENI, 3);
					break;
			}
			
			slice.removeComponents();
			
			// Build up the managers list which have resources
			for each(var nodeXml:XML in checkRspec.defaultNamespace::node)
			{
				var managerUrn:String;
				var useManager:GeniManager;
				if(importRspec.info.version < 1)
				{
					if(nodeXml.@component_manager_urn.length() == 1)
						managerUrn = nodeXml.@component_manager_urn;
					else
						managerUrn = nodeXml.@component_manager_uuid;
				}
				else
					managerUrn = nodeXml.@component_manager_id;
				
				useManager = GeniMain.geniUniverse.managers.getById(managerUrn);
				if(useManager == null && defaultManager != null)
				{
					useManager = defaultManager;
					if(importRspec.info.version < 1)
					{
						nodeXml.@component_manager_urn = defaultManager.id.full;
						nodeXml.@component_manager_uuid = defaultManager.id.full;
					}
					else
					{
						nodeXml.@component_manager_id = defaultManager.id.full;
					}
				}
				
				if(managersWithResources.indexOf(useManager) == -1)
					managersWithResources.push(useManager);
			}
			
			addMessage(
				"Importing into " + managersWithResources.length + " manager(s)",
				"Importing into " + managersWithResources.length + " manager(s)",
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			
			importRspec.document = checkRspec.toXMLString();
			
			// Import at each manager....
			for each(var managerWithResources:GeniManager in managersWithResources)
			{
				var importSliver:Sliver = slice.slivers.getByManager(managerWithResources);
				if(importSliver == null)
					importSliver = new Sliver(slice, managerWithResources);
				parent.add(new ParseRequestManifestTask(importSliver, importRspec, false));
			}
			
			afterComplete(false);
		}
		
		override protected function runCleanup():void
		{
			System.disposeXML(checkRspec);
		}
	}
}