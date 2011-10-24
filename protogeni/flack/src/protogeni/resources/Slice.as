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

package protogeni.resources
{
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import protogeni.Util;
	import protogeni.XmlUtil;
	import protogeni.communication.CommunicationUtil;
	import protogeni.communication.RequestQueueNode;
	import protogeni.display.ChooseManagerWindow;
	import protogeni.display.ImageUtil;

	/**
	 * Container for slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public class Slice
	{
		[Bindable]
		public var hrn:String = "";
		[Bindable]
		public var urn:IdnUrn = null;
		public function get Name():String {
			if(urn != null)
				return urn.name;
			else if(hrn != null)
				return hrn;
			else
				return "*No name*";
		}
		
		public var creator:GeniUser = null;
		public var credential:String = "";
		public var slivers:SliverCollection;
		
		public var expires:Date = null;
		
		[Bindable]
		public var useInputRspecVersion:Number = Util.defaultRspecVersion;
		
		private var _changing:Boolean = false;
		public function set Changing(val:Boolean):void {
			_changing = val;
		}
		public function get Changing():Boolean {
			return slivers.Changing || Main.geniHandler.requestHandler.isSliceChanging(this);
		}
		
		public function Slice()
		{
			slivers = new SliverCollection();
		}
		
		public function clearState():void {
			this._changing = false;
			for each(var sliver:Sliver in this.slivers.collection)
				sliver.clearState();
		}
		
		public function removeOutsideReferences():void {
			for each(var s:Sliver in this.slivers.collection) {
				s.removeOutsideReferences();
			}
		}
		
		public function clone(addOutsideReferences:Boolean = true):Slice
		{
			var newSlice:Slice = new Slice();
			newSlice.hrn = this.hrn;
			newSlice.urn = new IdnUrn(this.urn.full);
			newSlice.creator = this.creator;
			newSlice.credential = this.credential;
			newSlice.expires = this.expires;
			newSlice._changing = this._changing;
			newSlice.useInputRspecVersion = this.useInputRspecVersion;
			
			var sliver:Sliver;
			
			// Build up the basic slivers
			for each(sliver in this.slivers.collection)
			{
				var newSliver:Sliver = new Sliver(newSlice, sliver.manager);
				newSliver.urn = new IdnUrn(sliver.urn.full);
				newSliver.credential = sliver.credential;
				newSliver.expires = sliver.expires;
				newSliver.state = sliver.state;
				newSliver.status = sliver.status;
				newSliver.ticket = sliver.ticket;
				newSliver.request = sliver.request;
				newSliver.manifest = sliver.manifest;
				newSliver.extensionNamespaces = sliver.extensionNamespaces;
				newSliver.processed = sliver.processed;
				newSliver.changing = sliver.changing;
				newSliver.message = sliver.message;
				
				newSlice.slivers.add(newSliver);
			}
			
			var oldNodeToCloneNode:Dictionary = new Dictionary();
			var oldLinkToCloneLink:Dictionary = new Dictionary();
			var oldInterfaceToCloneInterface:Dictionary = new Dictionary();
			
			// Build up the slivers with nodes
			for each(sliver in this.slivers.collection)
			{
				newSliver = newSlice.slivers.getByManager(sliver.manager);
				
				// Build up nodes
				var retrace:Array = new Array();
				for each(var node:VirtualNode in sliver.nodes.collection)
				{
					if(oldNodeToCloneNode[node] != null)
						continue;
					var newNode:VirtualNode = new VirtualNode(newSlice.slivers.getByManager(node.manager));
					newNode.clientId = node.clientId;
					newNode.physicalNode = node.physicalNode;
					newNode.manager = node.manager;
					newNode.sliverId = node.sliverId;
					newNode.exclusive = node.exclusive;
					newNode.sliverType = node.sliverType;
					for each(var executeService:ExecuteService in node.executeServices) {
						newNode.executeServices.push(new ExecuteService(executeService.command,
																		executeService.shell));
					}
					for each(var installService:InstallService in node.installServices) {
						newNode.installServices.push(new InstallService(installService.url,
																		installService.installPath,
																		installService.fileType));
					}
					for each(var loginService:LoginService in node.loginServices) {
						newNode.loginServices.push(new LoginService(loginService.authentication,
																	loginService.hostname,
																	loginService.port,
																	loginService.username));
					}
					// supernode? add later ...
					// subnodes? add later ...
					retrace.push({clone:newNode, old:node});
					newNode.manifest = node.manifest;
					newNode.error = node.error;
					newNode.state = node.state;
					newNode.status = node.status;
					newNode.diskImage = node.diskImage;
					newNode.hardwareType = node.hardwareType;
					newNode.flackX = node.flackX;
					newNode.flackY = node.flackY;
					newNode.flackUnbound = node.flackUnbound;
					newNode.extensionsNodes = node.extensionsNodes;
					newNode.usesPlanetlabInitscript = node.usesPlanetlabInitscript;
					// depreciated
					newNode.virtualizationType = node.virtualizationType;
					newNode.virtualizationSubtype = node.virtualizationSubtype;
					
					// Add to slivers
					for each(var sliverToAddNode:Sliver in this.slivers.collection) {
						if(sliverToAddNode.nodes.contains(node))
							newSlice.slivers.getByManager(sliverToAddNode.manager).nodes.add(newNode);
					}
					
					// Copy interfaces
					for each(var vi:VirtualInterface in node.interfaces.collection)
					{
						var newVirtualInterface:VirtualInterface = new VirtualInterface(newNode);
						newVirtualInterface.id = vi.id;
						newVirtualInterface.physicalNodeInterface = vi.physicalNodeInterface;
						newVirtualInterface.capacity = vi.capacity;
						newVirtualInterface.ip = vi.ip;
						newVirtualInterface.netmask = vi.netmask;
						newVirtualInterface.type = vi.type;
						newNode.interfaces.add(newVirtualInterface);
						oldInterfaceToCloneInterface[vi] = newVirtualInterface;
						// links? add later ...
					}
					
					// Copy pipes
					for each(var vp:Pipe in node.pipes.collection)
						newNode.pipes.add(new Pipe(newNode.interfaces.GetByID(vp.source.id), newNode.interfaces.GetByID(vp.destination.id), vp.capacity, vp.latency, vp.packetLoss));
					
					//newSliver.nodes.addItem(newNode);
					
					oldNodeToCloneNode[node] = newNode;
				}
				
				// supernode and subnodes need to be added after to ensure they were created
				for each(var check:Object in retrace)
				{
					var cloneNode:VirtualNode = check.clone;
					var oldNode:VirtualNode = check.old;
					if(oldNode.superNode != null)
						cloneNode.superNode = newSliver.nodes.getByClientId(oldNode.clientId);
					if(oldNode.subNodes != null && oldNode.subNodes.length > 0)
					{
						for each(var subNode:VirtualNode in oldNode.subNodes.collection)
							cloneNode.subNodes.add(newSliver.nodes.getByClientId(subNode.clientId));
					}
				}
			}
			
			// Build up the links
			for each(sliver in this.slivers.collection)
			{
				newSliver = newSlice.slivers.getByManager(sliver.manager);
				
				for each(var link:VirtualLink in sliver.links.collection)
				{
					if(oldLinkToCloneLink[link] != null)
						continue;
					var newLink:VirtualLink = new VirtualLink();
					newLink.clientId = link.clientId;
					newLink.sliverId = link.sliverId;
					newLink.type = link.type;
					newLink.error = link.error;
					newLink.state = link.state;
					newLink.status = link.status;
					newLink.capacity = link.capacity;
					newLink.linkType = link.linkType;
					newLink.manifest = link.manifest;
					newLink.vlantag = link.vlantag;
					for each(var linkSliver:Sliver in link.interfaces.Slivers.collection)
						newSlice.slivers.getByManager(linkSliver.manager).links.add(newLink);
					
					var slivers:Vector.<Sliver> = new Vector.<Sliver>();
					for each(var i:VirtualInterface in link.interfaces.collection)
					{
						var newInterface:VirtualInterface = oldInterfaceToCloneInterface[i];
						newLink.interfaces.add(newInterface);
						newInterface.virtualLinks.add(newLink);
					}
					
					oldLinkToCloneLink[link] = newLink;
				}
			}
			
			return newSlice;
		}
		
		public function ReadyIcon():Class {
			switch(this.slivers.Status) {
				case Sliver.STATUS_READY: 		return ImageUtil.flagGreenIcon;
				case Sliver.STATUS_MIXED:
				case Sliver.STATUS_CHANGING:
				case Sliver.STATUS_NOTREADY:	return ImageUtil.flagYellowIcon;
				case Sliver.STATUS_FAILED:		return ImageUtil.flagRedIcon;
				case Sliver.STATUS_UNKNOWN:
				default:						return ImageUtil.flagOrangeIcon;
			}
		}
		
		public function getOrCreateForManager(gm:GeniManager):Sliver
		{
			var newSliver:Sliver = this.slivers.getByManager(gm);
			if(newSliver == null) {
				newSliver = new Sliver(this, gm);
				this.slivers.add(newSliver);
			}
			return newSliver;
		}
		
		public function tryImport(rspec:String):Boolean {
			// Tell user they need to delete
			if(this.slivers.AllocatedAnyResources)
				Alert.show("The slice has resources allocated to it.  Please delete the slice before trying to import.", "Allocated Resources Exist");
			else if(this.slivers.VirtualNodes.length > 0)
				Alert.show("The slice already has resources waiting to be allocated.  Please clear the canvas before trying to import", "Resources Exist");
			else {
				var sliceRspec:XML;
				try
				{
					sliceRspec = new XML(rspec);
				}
				catch(e:Error)
				{
					Alert.show("There is a problem with the XML: " + e.toString());
					return false;
				}
				
				var defaultNamespace:Namespace = sliceRspec.namespace();
				var detectedRspecVersion:Number;
				switch(defaultNamespace.uri) {
					case XmlUtil.rspec01Namespace:
						detectedRspecVersion = 0.1;
						break;
					case XmlUtil.rspec02Namespace:
					case XmlUtil.rspec02MalformedNamespace:
						detectedRspecVersion = 0.2;
						break;
					case XmlUtil.rspec2Namespace:
						detectedRspecVersion = 2;
						break;
					case XmlUtil.rspec3Namespace:
						detectedRspecVersion = 3;
						break;
					default:
						Alert.show("Please use a compatible RSPEC");
						return false;
				}
				
				for each(var nodeXml:XML in sliceRspec.defaultNamespace::node)
				{
					var managerUrn:String;
					if(detectedRspecVersion < 1) {
						if(nodeXml.@component_manager_urn.length() == 1)
							managerUrn = nodeXml.@component_manager_urn;
						else
							managerUrn = nodeXml.@component_manager_uuid;
					} else
						managerUrn = nodeXml.@component_manager_id;
					if(managerUrn.length == 0) {
						var chooseManagerWindow:ChooseManagerWindow = new ChooseManagerWindow();
						chooseManagerWindow.success = function importWithDefault(manager:GeniManager):void {
															doImport(sliceRspec, manager);
														}
						chooseManagerWindow.showWindow();
						return true;
					}
				}
				
				return this.doImport(sliceRspec);
			}
			return false;
		}
		
		public function doImport(sliceRspec:XML, defaultManager:GeniManager = null):Boolean {
			
			// Detect managers
			try {
				var defaultNamespace:Namespace = sliceRspec.namespace();
				var detectedRspecVersion:Number;
				var detectedManagers:Vector.<GeniManager> = new Vector.<GeniManager>();
				switch(defaultNamespace.uri) {
					case XmlUtil.rspec01Namespace:
						detectedRspecVersion = 0.1;
						break;
					case XmlUtil.rspec02Namespace:
					case XmlUtil.rspec02MalformedNamespace:
						detectedRspecVersion = 0.2;
						break;
					case XmlUtil.rspec2Namespace:
						detectedRspecVersion = 2;
						break;
					case XmlUtil.rspec3Namespace:
						detectedRspecVersion = 3;
						break;
				}
			}
			catch(e:Error)
			{
				Alert.show("Please use a compatible RSPEC");
				return false;
			}
			
			this.slivers = new SliverCollection();
			
			// Set the unknown managers to the default manager if set
			if(defaultManager != null) {
				for each(var testNodeXml:XML in sliceRspec.defaultNamespace::node)
				{
					var testManagerUrn:String;
					if(detectedRspecVersion < 1) {
						if(testNodeXml.@component_manager_urn.length() == 1)
							testManagerUrn = testNodeXml.@component_manager_urn;
						else
							testManagerUrn = testNodeXml.@component_manager_uuid;
					} else
						testManagerUrn = testNodeXml.@component_manager_id;
					if(testManagerUrn.length == 0) {
						if(detectedRspecVersion < 1)
							testNodeXml.@component_manager_urn = defaultManager.Urn.full;
						else
							testNodeXml.@component_manager_id = defaultManager.Urn.full;
					}
				}
			}
			
			for each(var nodeXml:XML in sliceRspec.defaultNamespace::node)
			{
				var managerUrn:String;
				var detectedManager:GeniManager;
				if(detectedRspecVersion < 1) {
					if(nodeXml.@component_manager_urn.length() == 1)
						managerUrn = nodeXml.@component_manager_urn;
					else
						managerUrn = nodeXml.@component_manager_uuid;
				} else
					managerUrn = nodeXml.@component_manager_id;
				
				if(managerUrn.length == 0) {
					Alert.show("All nodes must have a manager associated with them");
					return false;
				} else
					detectedManager = Main.geniHandler.GeniManagers.getByUrn(managerUrn);
				
				if(detectedManager == null) {
					Alert.show("Unkown manager referenced: " + managerUrn);
					return false;
				} else if(detectedManager.Status != GeniManager.STATUS_VALID) {
					Alert.show("Known manager referenced (" + managerUrn + "), but manager didn't load successfully. Please restart Flack.");
					return false;
				}
				
				if(detectedManager != null && detectedManagers.indexOf(detectedManager) == -1) {
					var newSliver:Sliver = this.getOrCreateForManager(detectedManager);
					try {
						newSliver.parseRspec(sliceRspec);
					} catch(e:Error) {
						Alert.show("Error while parsing sliver RSPEC on " + detectedManager.Hrn + ": " + e.toString());
						return false;
					}
					detectedManagers.push(detectedManager);
				}
			}
			
			Main.geniDispatcher.dispatchSliceChanged(this);
			return true;
		}
	}
}