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
	import com.flack.geni.RspecUtil;
	import com.flack.geni.resources.Property;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.physical.PhysicalLocation;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.virtual.ExecuteService;
	import com.flack.geni.resources.virtual.GeniManagerReference;
	import com.flack.geni.resources.virtual.InstallService;
	import com.flack.geni.resources.virtual.LinkType;
	import com.flack.geni.resources.virtual.LoginService;
	import com.flack.geni.resources.virtual.Pipe;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualInterfaceReference;
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.geni.resources.virtual.VirtualLinkCollection;
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;
	import com.flack.geni.resources.virtual.extensions.ClientInfo;
	import com.flack.geni.resources.virtual.extensions.slicehistory.SliceHistoryItem;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.utils.CompressUtil;
	import com.flack.shared.utils.DateUtil;
	
	import flash.system.System;
	
	/**
	 * Generates a request document for the slice using the slice's settings
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GenerateRequestManifestTask extends Task
	{
		public var slice:Slice;
		public var sliver:Sliver;
		public var includeHistory:Boolean;
		public var includeManifest:Boolean;
		public var resultRspec:Rspec;
		
		/**
		 * 
		 * @param newSlice Slice for which to create the request for
		 * @param newSliverOnly Sliver for which to limit the request to
		 * @param shouldIncludeHistory Include the history?
		 * 
		 */
		public function GenerateRequestManifestTask(newSlice:Slice, newSliverOnly:Sliver = null, shouldIncludeHistory:Boolean = true, shouldIncludeManifestInfo:Boolean = false)
		{
			super(
				"Generate request RSPEC",
				"Generates a request for a slice",
				"",
				null,
				0,
				0,
				false,
				[newSlice]);
			slice = newSlice;
			sliver = newSliverOnly;
			includeHistory = shouldIncludeHistory;
			includeManifest = shouldIncludeManifestInfo;
		}
		
		override protected function runStart():void
		{
			if(sliver != null && sliver.forceUseInputRspecInfo != null)
			{
				resultRspec = new Rspec(
					"",
					sliver.forceUseInputRspecInfo,
					null, null, Rspec.TYPE_REQUEST
				);
			}
			else
			{
				resultRspec = new Rspec(
					"",
					slice.useInputRspecInfo,
					null, null, Rspec.TYPE_REQUEST
				);
			}
			
			
			var xmlDocument:XML;
			if(slice.slivers.length > 0)
				xmlDocument = slice.slivers.collection[0].extensions.createAndApply("rspec");
			else
				xmlDocument = <rspec />;
			xmlDocument.@type = includeManifest ? "manifest" : "request";
			xmlDocument.@generated_by = "Flack";
			xmlDocument.@generated = DateUtil.toRFC3339(new Date());
			
			// Add default namespaces
			var defaultNamespace:Namespace;
			switch(resultRspec.info.version)
			{
				case 0.1:
					defaultNamespace = new Namespace(null, RspecUtil.rspec01Namespace);
					break;
				case 0.2:
					defaultNamespace = new Namespace(null, RspecUtil.rspec02Namespace);
					break;
				case 2:
					defaultNamespace = new Namespace(null, RspecUtil.rspec2Namespace);
					break;
				case 3:
					defaultNamespace = new Namespace(null, RspecUtil.rspec3Namespace);
					break;
			}
			xmlDocument.setNamespace(defaultNamespace);
			if(resultRspec.info.version >= 2)
			{
				xmlDocument.addNamespace(RspecUtil.flackNamespace);
				xmlDocument.addNamespace(RspecUtil.clientNamespace);
			}
			var xsiNamespace:Namespace = RspecUtil.xsiNamespace;
			xmlDocument.addNamespace(xsiNamespace);
			
			// Add default schema locations
			var schemaLocations:String;
			switch(resultRspec.info.version)
			{
				case 0.1:
					schemaLocations = RspecUtil.rspec01SchemaLocation;
					break;
				case 0.2:
					schemaLocations = RspecUtil.rspec02SchemaLocation;
					break;
				case 2:
					schemaLocations = RspecUtil.rspec2SchemaLocation;
					break;
				case 3:
					schemaLocations = RspecUtil.rspec3SchemaLocation;
					break;
			}
			var nodes:VirtualNodeCollection = sliver == null ? slice.nodes : sliver.Nodes;
			var links:VirtualLinkCollection = sliver == null ? slice.links : sliver.Links;
			if(nodes.getBySliverType(SliverTypes.DELAY).length > 0)
			{
				xmlDocument.addNamespace(RspecUtil.delayNamespace);
				schemaLocations += " " + RspecUtil.delaySchemaLocation;
			}
			xmlDocument.@xsiNamespace::schemaLocation = schemaLocations;
			// XXX add extension schema namespaces...
			
			for each(var node:VirtualNode in nodes.collection)
				xmlDocument.appendChild(generateNodeRspec(node, false, resultRspec.info));
			
			for each(var link:VirtualLink in links.collection)
				xmlDocument.appendChild(generateLinkRspec(link, resultRspec.info));
			
			if(resultRspec.info.version >= 2)
			{
				// Add client extension
				slice.clientInfo = new ClientInfo();
				var clientInfoXml:XML = <client_info />;
				clientInfoXml.setNamespace(RspecUtil.clientNamespace);
				clientInfoXml.@name = slice.clientInfo.name;
				clientInfoXml.@environment = slice.clientInfo.environment;
				clientInfoXml.@version = slice.clientInfo.version;
				clientInfoXml.@url = slice.clientInfo.url;
				xmlDocument.appendChild(clientInfoXml);
				
				// Add history extension
				if(includeHistory && slice.history.states.length > 0)
				{
					var sliceHistoryXml:XML = <slice_history />;
					sliceHistoryXml.@backIndex = slice.history.backIndex;
					sliceHistoryXml.@note = slice.history.stateName;
					sliceHistoryXml.setNamespace(RspecUtil.historyNamespace);
					for each(var state:SliceHistoryItem in slice.history.states)
					{
						var slicHistoryItemXml:XML = <state>{CompressUtil.compress(state.rspec)}</state>;
						if(state.note.length > 0)
							sliceHistoryXml.@note = state.note;
						slicHistoryItemXml.setNamespace(RspecUtil.historyNamespace);
						sliceHistoryXml.appendChild(new XML(slicHistoryItemXml));
					}
					xmlDocument.appendChild(sliceHistoryXml);
				}
				
				// add flack extension
				var sliceInfoXml:XML = <slice_info />;
				sliceInfoXml.setNamespace(RspecUtil.flackNamespace);
				sliceInfoXml.@view = slice.flackInfo.view;
				xmlDocument.appendChild(sliceInfoXml);
			}
			
			resultRspec.document = xmlDocument.toXMLString();
			System.disposeXML(xmlDocument);
			
			data = resultRspec;
				
			super.afterComplete(false);
		}
		
		public function generateNodeRspec(node:VirtualNode,
										  removeNonexplicitBinding:Boolean,
										  version:RspecVersion):XML
		{
			var nodeXml:XML = node.extensions.createAndApply("node");
			if(version.version < 1)
			{
				nodeXml.@virtual_id = node.clientId;
				nodeXml.@component_manager_uuid = node.manager.id.full;
				nodeXml.@component_manager_urn = node.manager.id.full;
				if(node.sliverType.name == SliverTypes.JUNIPER_LROUTER)
					nodeXml.@virtualization_type = SliverTypes.JUNIPER_LROUTER;
				else
				{
					nodeXml.@virtualization_type = "emulab-vnode";
					if(node.sliverType.name == SliverTypes.EMULAB_OPENVZ)
						nodeXml.@virtualization_subtype = SliverTypes.EMULAB_OPENVZ;
				}
				if(node.hardwareType.name.length == 0)
				{
					var nodeType:String = "";
					if(node.sliverType.name == SliverTypes.RAWPC_V2)
						nodeType = "pc";
					else if(node.sliverType.name == SliverTypes.EMULAB_OPENVZ)
						nodeType = "pcvm";
					else if(node.sliverType.name == SliverTypes.JUNIPER_LROUTER)
						nodeType = SliverTypes.JUNIPER_LROUTER;
					var nodeTypeXml:XML = <node_type />;
					nodeTypeXml.@type_name = nodeType;
					nodeTypeXml.@type_slots = 1;
					nodeXml.appendChild(nodeTypeXml);
				}
				if(includeManifest && node.id != null && node.id.full.length > 0)
					nodeXml.@sliver_urn = node.id.full;
			}
			else
			{
				nodeXml.@client_id = node.clientId;
				nodeXml.@component_manager_id = node.manager.id.full;
				if(includeManifest && node.id != null && node.id.full.length > 0)
					nodeXml.@sliver_id = node.id.full;
			}
			
			// Hack for INSTOOLS w/o namespace
			if(node.mcInfo != null)
			{
				nodeXml.@MC = "1";
				if(node.mcInfo.type.length > 0)
					nodeXml.@mc_type = node.mcInfo.type;
			}
			
			if (node.Bound && !(removeNonexplicitBinding && node.flackInfo.unbound))
			{
				if(version.version < 1)
				{
					nodeXml.@component_uuid = node.physicalId.full;
					nodeXml.@component_urn = node.physicalId.full;
				}
				else
				{
					nodeXml.@component_id = node.physicalId.full;
					nodeXml.@component_name = node.Physical.name;
				}
			}
			
			if (!node.exclusive)
			{
				if(version.version < 1)
					nodeXml.@exclusive = 0;
				else
					nodeXml.@exclusive = "false";
			}
			else
			{
				if(version.version < 1)
					nodeXml.@exclusive = 1;
				else
					nodeXml.@exclusive = "true";
			}
			
			// If node is at a location, include it
			// Mostly so managers outside of this node's manager can know a location
			if(node.Physical != null && node.Physical.location.latitude != PhysicalLocation.defaultLatitude)
			{
				var locationXml:XML = <location />;
				locationXml.@latitude = node.Physical.location.latitude;
				locationXml.@longitude = node.Physical.location.longitude;
				locationXml.@country = node.Physical.location.country;
				nodeXml.appendChild(locationXml);
			}
			
			if(node.hardwareType.name.length > 0)
			{
				if(version.version < 1)
				{
					var nodeTypeHardwareTypeXml:XML = <node_type />;
					nodeTypeHardwareTypeXml.@type_name = node.hardwareType.name;
					nodeTypeHardwareTypeXml.@type_slots = node.hardwareType.slots;
					nodeXml.appendChild(nodeTypeHardwareTypeXml);
				}
				else
				{
					var nodeHardwareType:XML = <hardware_type />;
					nodeHardwareType.@name = node.hardwareType.name;
					nodeXml.appendChild(nodeHardwareType);
				}
			}
			
			if(version.version < 2)
			{
				if(node.sliverType.selectedImage != null && node.sliverType.selectedImage.id.full.length > 0
					&& version.version > 0.1)
				{
					var diskImageXml:XML = node.sliverType.selectedImage.extensions.createAndApply("disk_image");
					diskImageXml.@name = node.sliverType.selectedImage.id.full;
					nodeXml.appendChild(diskImageXml);
				}
			}
			else if (node.sliverType.name.length > 0)
			{
				var sliverType:XML = node.sliverType.extensions.createAndApply("sliver_type");
				sliverType.@name = node.sliverType.name;
				if(node.sliverType.name == SliverTypes.DELAY)
				{
					var sliverTypeShapingXml:XML = <sliver_type_shaping />;
					sliverTypeShapingXml.setNamespace(RspecUtil.delayNamespace);
					//sliverTypeShapingXml.@xmlns = XmlUtil.delayNamespace.uri;
					if(node.sliverType.pipes != null)
					{
						for each(var pipe:Pipe in node.sliverType.pipes.collection)
						{
							var pipeXml:XML = <pipe />;
							pipeXml.setNamespace(RspecUtil.delayNamespace);
							pipeXml.@source = pipe.src.id.full;
							pipeXml.@dest = pipe.dst.id.full;
							if(pipe.capacity)
								pipeXml.@capacity = pipe.capacity;
							else
								pipeXml.@capacity = 0;
							if(pipe.packetLoss)
								pipeXml.@packet_loss = pipe.packetLoss;
							else
								pipeXml.@packet_loss = 0;
							if(pipe.latency)
								pipeXml.@latency = pipe.latency;
							else
								pipeXml.@latency = 0;
							sliverTypeShapingXml.appendChild(pipeXml);
						}
					}
					
					sliverType.appendChild(sliverTypeShapingXml);
				}
				else if(node.sliverType.name == SliverTypes.FIREWALL)
				{
					var firewallConfigXml:XML = <firewall_config />;
					firewallConfigXml.setNamespace(RspecUtil.firewallNamespace);
					firewallConfigXml.@style = node.sliverType.firewallStyle;
					if(node.sliverType.firewallType.length > 0)
						firewallConfigXml.@type = node.sliverType.firewallType;
					sliverType.appendChild(firewallConfigXml);
				}
				if(node.sliverType.selectedImage != null && node.sliverType.selectedImage.id.full.length > 0)
				{
					var sliverDiskImageXml:XML = node.sliverType.selectedImage.extensions.createAndApply("disk_image");
					sliverDiskImageXml.@name = node.sliverType.selectedImage.id.full;
					sliverType.appendChild(sliverDiskImageXml);
				}
				if(node.sliverType.selectedPlanetLabInitscript.length > 0)
				{
					var planetlabInitscriptXml:XML = new XML("<initscript name=\""+node.sliverType.selectedPlanetLabInitscript+"\" />");
					planetlabInitscriptXml.setNamespace(RspecUtil.planetlabNamespace);
					sliverType.appendChild(planetlabInitscriptXml);
				}
				nodeXml.appendChild(sliverType);
			}
			
			// Services
			if(version.version < 1)
			{
				if(node.services.executeServices != null && node.services.executeServices.length > 0)
					nodeXml.@startup_command = node.services.executeServices[0].command;
				if(node.services.installServices != null && node.services.installServices.length > 0)
					nodeXml.@tarfiles = node.services.installServices[0].url;
				if(includeManifest && node.services.loginServices != null && node.services.loginServices.length > 0)
				{
					var servicesXml:XML = <services />;
					for each(var login1Service:LoginService in node.services.loginServices)
					{
						var login1Xml:XML = <login />
						login1Xml.@authentication = login1Service.authentication;
						login1Xml.@hostname = login1Service.hostname;
						login1Xml.@port = login1Service.port;
						login1Xml.@username = login1Service.username;
						servicesXml.appendChild(login1Xml);
						
						nodeXml.@hostname = login1Service.hostname;
						nodeXml.@sshdport = login1Service.port;
					}
					nodeXml.appendChild(servicesXml);
				}
			}
			else
			{
				var serviceXml:XML = node.services.extensions.createAndApply("services");
				if(node.services.executeServices != null)
				{
					for each(var executeService:ExecuteService in node.services.executeServices)
					{
						var executeXml:XML = executeService.extensions.createAndApply("execute");
						executeXml.@command = executeService.command;
						executeXml.@shell = executeService.shell;
						serviceXml.appendChild(executeXml);
					}
				}
				if(node.services.installServices != null)
				{
					for each(var installService:InstallService in node.services.installServices)
					{
						var installXml:XML = installService.extensions.createAndApply("install");
						installXml.@install_path = installService.installPath;
						installXml.@url = installService.url;
						serviceXml.appendChild(installXml);
					}
				}
				if(includeManifest && node.services.loginServices != null)
				{
					for each(var loginService:LoginService in node.services.loginServices)
					{
						var loginXml:XML = loginService.extensions.createAndApply("login");
						loginXml.@authentication = loginService.authentication;
						loginXml.@hostname = loginService.hostname;
						loginXml.@port = loginService.port;
						loginXml.@username = loginService.username;
						serviceXml.appendChild(loginXml);
					}
				}
				
				if(serviceXml.children().length() > 0)
					nodeXml.appendChild(serviceXml);
			}
			
			if (version.version < 1 && node.superNode != null)
				nodeXml.appendChild(XML("<subnode_of>" + node.superNode.clientId + "</subnode_of>"));
			
			for each (var current:VirtualInterface in node.interfaces.collection)
			{
				var interfaceXml:XML = current.extensions.createAndApply("interface");
				if(version.version < 1)
				{
					interfaceXml.@virtual_id = current.clientId;
					if(includeManifest)
					{
						if(current.id != null && current.id.full.length > 0)
							interfaceXml.@sliver_urn = current.id.full;
						//if(current.physicalId != null && current.physicalId.full.length > 0)
						//	interfaceXml.@component_id = current.physicalId.full.substr(current.physicalId.full.lastIndexOf(":"));
					}
				}
				else
				{
					interfaceXml.@client_id = current.clientId;
					if(includeManifest)
					{
						if(current.id != null && current.id.full.length > 0)
							interfaceXml.@sliver_id = current.id.full;
						if(current.physicalId != null && current.physicalId.full.length > 0)
							interfaceXml.@component_id = current.physicalId.full;
					}
					if(current.ip != null && current.ip.address.length > 0)
					{
						var ipXml:XML = current.ip.extensions.createAndApply("ip");
						ipXml.@address = current.ip.address;
						ipXml.@netmask = current.ip.netmask;
						ipXml.@type = current.ip.type;
						interfaceXml.appendChild(ipXml);
					}
				}
				nodeXml.appendChild(interfaceXml);
			}
			
			if(version.version >= 2)
			{
				var flackXml:XML = <node_info />;
				flackXml.setNamespace(RspecUtil.flackNamespace);
				flackXml.@x = node.flackInfo.x;
				flackXml.@y = node.flackInfo.y;
				flackXml.@unbound = node.flackInfo.unbound;
				nodeXml.appendChild(flackXml);
			}
			
			return nodeXml;
		}
		
		public function generateLinkRspec(link:VirtualLink, version:RspecVersion):XML
		{
			var linkXml:XML = link.extensions.createAndApply("link");
			
			if(version.version < 1)
			{
				linkXml.@virtual_id = link.clientId;
				if(includeManifest && link.id != null && link.id.full.length > 0)
					linkXml.@sliver_urn = link.id.full;
			}
			else
			{
				linkXml.@client_id = link.clientId;
				if(includeManifest && link.id != null && link.id.full.length > 0)
					linkXml.@sliver_id = link.id.full;
			}
			
			var manager:GeniManager;
			
			var managersCollection:GeniManagerCollection = link.interfaceRefs.Interfaces.Managers;
			for each(manager in managersCollection.collection)
			{
				var cmXml:XML;
				var managerRef:GeniManagerReference = link.managerRefs.getReferenceFor(manager);
				if(managerRef == null)
					cmXml = <component_manager />;
				else
					cmXml = managerRef.extensions.createAndApply("component_manager");
				cmXml.@name = manager.id.full;
				linkXml.appendChild(cmXml);
			}
			
			for each (var currentReference:VirtualInterfaceReference in link.interfaceRefs.collection)
			{
				var interfaceRefXml:XML = currentReference.extensions.createAndApply("interface_ref");
				if(version.version < 1)
				{
					interfaceRefXml.@virtual_node_id = currentReference.referencedInterface.Owner.clientId;
					if(includeManifest)
					{
						if(currentReference.referencedInterface.id != null && currentReference.referencedInterface.id.full.length > 0)
							interfaceRefXml.@sliver_urn = currentReference.referencedInterface.id.full;
						if(currentReference.referencedInterface.physicalId != null && currentReference.referencedInterface.physicalId.full.length > 0)
							interfaceRefXml.@component_urn = currentReference.referencedInterface.physicalId.full;
					}
					
					if (link.type.name == LinkType.GRETUNNEL_V2)
					{
						interfaceRefXml.@tunnel_ip = currentReference.referencedInterface.ip.address;
						interfaceRefXml.@virtual_interface_id = "control";
					}
					else
					{
						interfaceRefXml.@virtual_interface_id = currentReference.referencedInterface.clientId;
						if(currentReference.referencedInterface.ip != null && currentReference.referencedInterface.ip.address.length > 0)
						{
							interfaceRefXml.@IP = currentReference.referencedInterface.ip.address;
							interfaceRefXml.@netmask = currentReference.referencedInterface.ip.netmask;
						}
					}
				}
				else
					interfaceRefXml.@client_id = currentReference.referencedInterface.clientId;
				
				linkXml.appendChild(interfaceRefXml);
			}
			
			if(version.version < 1)
			{
				if(link.Capacity > 0)
				{
					linkXml.appendChild(XML("<bandwidth>" + link.Capacity + "</bandwidth>"));
					linkXml.@bandwidth = link.Capacity;
				}
				if(link.Latency > 0)
					linkXml.appendChild(XML("<latency>" + link.Latency + "</latency>"));
				if(link.PacketLoss > 0)
					linkXml.appendChild(XML("<packet_loss>" + link.PacketLoss + "</packet_loss>"));
			}
			else
			{
				for each(var property:Property in link.properties.collection)
				{
					var propertyXml:XML = property.extensions.createAndApply("property");
					propertyXml.@source_id = (property.source as VirtualInterface).clientId;
					propertyXml.@dest_id = (property.destination as VirtualInterface).clientId;
					propertyXml.@capacity = property.capacity;
					propertyXml.@latency = property.latency;
					propertyXml.@packet_loss = property.packetLoss;
					linkXml.appendChild(propertyXml);
				}
			}
			
			switch(link.type.name)
			{
				case LinkType.GRETUNNEL_V1:
				case LinkType.GRETUNNEL_V2:
					var gretunnel_type:XML = link.type.extensions.createAndApply("link_type");
					if(version.version < 1)
					{
						gretunnel_type.setChildren(LinkType.GRETUNNEL_V1);
						linkXml.@link_type = LinkType.GRETUNNEL_V1;
						gretunnel_type.@name = LinkType.GRETUNNEL_V1;
						gretunnel_type.@link_type = LinkType.GRETUNNEL_V1;
					}
					else
						gretunnel_type.@name = LinkType.GRETUNNEL_V2;
					linkXml.appendChild(gretunnel_type);
					break;
				case LinkType.ION:
					for each(manager in link.interfaceRefs.Interfaces.Managers.collection)
					{
						var componentHopIonXml:XML = <component_hop />;
						componentHopIonXml.@component_urn = IdnUrn.makeFrom(manager.id.authority, "link", "ion").full;
						interfaceRefXml = <interface_ref />;
						interfaceRefXml.@component_node_urn = IdnUrn.makeFrom(manager.id.authority, "node", "ion").full;
						interfaceRefXml.@component_interface_id = "eth0";
						componentHopIonXml.appendChild(interfaceRefXml);
						linkXml.appendChild(componentHopIonXml);
					}
					break;
				case LinkType.GPENI:
					for each(manager in link.interfaceRefs.Interfaces.Managers.collection)
					{
						var componentHopGpeniXml:XML = <component_hop />;
						componentHopGpeniXml.@component_urn = IdnUrn.makeFrom(
							manager.id.authority,
							"link",
							"gpeni").full;
						interfaceRefXml = <interface_ref />;
						interfaceRefXml.@component_node_urn = IdnUrn.makeFrom(
							manager.id.authority,
							"node",
							"gpeni").full;
						interfaceRefXml.@component_interface_id = "eth0";
						componentHopGpeniXml.appendChild(interfaceRefXml);
						linkXml.appendChild(componentHopGpeniXml);
					}
					break;
				case LinkType.LAN_V1:
				case LinkType.LAN_V2:
					var lan_type:XML = link.type.extensions.createAndApply("link_type");
					if(version.version < 1)
					{
						lan_type.setChildren(LinkType.LAN_V1);
						linkXml.@link_type = LinkType.LAN_V1;
						lan_type.@link_type = LinkType.LAN_V1;
						lan_type.@name = LinkType.LAN_V1;
					}
					else
						lan_type.@name = LinkType.LAN_V2;
					linkXml.appendChild(lan_type);
					break;
			}
			
			return linkXml;
		}
	}
}