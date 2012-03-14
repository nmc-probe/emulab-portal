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
	import com.flack.geni.resources.DiskImage;
	import com.flack.geni.resources.Property;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.physical.HardwareType;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.ExecuteService;
	import com.flack.geni.resources.virtual.GeniManagerReference;
	import com.flack.geni.resources.virtual.Host;
	import com.flack.geni.resources.virtual.InstallService;
	import com.flack.geni.resources.virtual.Ip;
	import com.flack.geni.resources.virtual.LinkType;
	import com.flack.geni.resources.virtual.LoginService;
	import com.flack.geni.resources.virtual.Pipe;
	import com.flack.geni.resources.virtual.PipeCollection;
	import com.flack.geni.resources.virtual.Services;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualInterfaceReference;
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;
	import com.flack.geni.resources.virtual.extensions.MCInfo;
	import com.flack.geni.resources.virtual.extensions.SliceFlackInfo;
	import com.flack.geni.resources.virtual.extensions.slicehistory.SliceHistory;
	import com.flack.geni.resources.virtual.extensions.slicehistory.SliceHistoryItem;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.CompressUtil;
	import com.flack.shared.utils.DateUtil;
	import com.flack.shared.utils.StringUtil;
	
	import flash.system.System;
	import flash.utils.Dictionary;
	
	/**
	 * Parses the given RSPEC into the sliver's slice
	 * 
	 * @author mstrum
	 * 
	 */
	public final class ParseRequestManifestTask extends Task
	{
		public var sliver:Sliver;
		public var rspec:Rspec;
		public var markUnsubmitted:Boolean;
		public var parseManifest:Boolean;
		private var xmlDocument:XML;
		
		/**
		 * 
		 * @param newSliver Sliver for which to parse the rspec for
		 * @param newRspec Rspec to parse
		 * @param shouldMarkUnsubmitted Mark all resources as unsubmitted, must be false to import manifest values
		 * 
		 */
		public function ParseRequestManifestTask(newSliver:Sliver,
												 newRspec:Rspec,
												 shouldMarkUnsubmitted:Boolean = false,
												 shouldParseManifest:Boolean = false)
		{
			super(
				"Process RSPEC @ " + newSliver.manager.hrn,
				"Process the request/manifest for a sliver",
				"Process RSPEC",
				null,
				0,
				0,
				false,
				[newSliver, newSliver.slice, newSliver.manager]
			);
			sliver = newSliver;
			rspec = newRspec;
			markUnsubmitted = shouldMarkUnsubmitted;
			parseManifest = shouldParseManifest;
		}
		
		override protected function runCleanup():void
		{
			System.disposeXML(xmlDocument);
		}
		
		override protected function runStart():void
		{
			try
			{
				xmlDocument = new XML(rspec.document);
				//var namespaces:Array = xmlDocument.namespaceDeclarations();
			}
			catch(e:Error)
			{
				afterError(
					new TaskError(
						"Bad XML",
						TaskError.CODE_PROBLEM
					)
				);
				return;
			}
			
			try
			{
				var defaultNamespace:Namespace = xmlDocument.namespace();
				switch(defaultNamespace.uri)
				{
					case RspecUtil.rspec01Namespace:
					case RspecUtil.rspec01MalformedNamespace:
						rspec.info = new RspecVersion(RspecVersion.TYPE_PROTOGENI, 0.1);
						break;
					case RspecUtil.rspec02Namespace:
					case RspecUtil.rspec02MalformedNamespace:
						rspec.info = new RspecVersion(RspecVersion.TYPE_PROTOGENI, 0.2);
						break;
					case RspecUtil.rspec2Namespace:
						rspec.info = new RspecVersion(RspecVersion.TYPE_PROTOGENI, 2);
						break;
					case RspecUtil.rspec3Namespace:
						rspec.info = new RspecVersion(RspecVersion.TYPE_GENI, 3);
						break;
					default:
						afterError(
							new TaskError(
								"Namespace not supported. Manifest RSPEC with the namespace '"
								+defaultNamespace.uri+ "' is not supported.",
								TaskError.CODE_PROBLEM
							)
						);
						return;
				}
				sliver.slice.useInputRspecInfo = new RspecVersion(rspec.info.type, rspec.info.version);
				
				if(xmlDocument.@valid_until.length() == 1)
					sliver.expires = DateUtil.parseRFC3339(String(xmlDocument.@valid_until));
				if(xmlDocument.@expires.length() == 1)
					sliver.expires = DateUtil.parseRFC3339(String(xmlDocument.@expires));
				
				sliver.markStaged();
				
				var nodesById:Dictionary = new Dictionary();
				var interfacesById:Dictionary = new Dictionary();
				
				var localName:String;
				
				sliver.extensions.buildFromOriginal(
					xmlDocument,
					[
						defaultNamespace.uri,
						RspecUtil.xsiNamespace.uri,
						RspecUtil.flackNamespace.uri,
						RspecUtil.clientNamespace.uri,
						RspecUtil.historyNamespace.uri
					]
				);
				
				for each(var nodeXml:XML in xmlDocument.defaultNamespace::node)
				{
					// Get IDs
					var managerIdString:String = "";
					var componentIdString:String = "";
					var clientIdString:String = "";
					var sliverIdString:String = "";
					
					if(rspec.info.version < 1)
					{
						if(nodeXml.@component_manager_urn.length() == 1)
							managerIdString = String(nodeXml.@component_manager_urn);
						else if(nodeXml.@component_manager_uuid.length() == 1)
							managerIdString = String(nodeXml.@component_manager_uuid);
						
						if(nodeXml.@component_urn.length() == 1)
							componentIdString = String(nodeXml.@component_urn);
						else if(nodeXml.@component_uuid.length() == 1)
							componentIdString = String(nodeXml.@component_uuid);
						
						clientIdString = String(nodeXml.@virtual_id);
						
						if(nodeXml.@sliver_urn.length() == 1)
							sliverIdString = String(nodeXml.@sliver_urn);
						else if(nodeXml.@sliver_uuid.length() == 1)
							sliverIdString = String(nodeXml.@sliver_uuid);
					}
					else
					{
						if(nodeXml.@component_manager_id.length() == 1)
							managerIdString = String(nodeXml.@component_manager_id);
						
						if(nodeXml.@component_id.length() == 1)
							componentIdString = String(nodeXml.@component_id);
						
						clientIdString = String(nodeXml.@client_id);
						
						sliverIdString = String(nodeXml.@sliver_id);
					}
					
					// Things without client-ids aren't in the sliver at all...
					if(clientIdString.length == 0)
						continue;
					
					// Managers must be specified...
					if(managerIdString.length == 0)
					{
						afterError(
							new TaskError(
								"No Manager specified for node described as: " + nodeXml.toXMLString(),
								TaskError.CODE_PROBLEM
							)
						);
						return;
					}
					var virtualNodeManager:GeniManager = GeniMain.geniUniverse.managers.getById(managerIdString);
					if(virtualNodeManager == null)
					{
						afterError(
							new TaskError(
								"Manager with ID '"+managerIdString+"' was not found for node named " + clientIdString,
								TaskError.CODE_PROBLEM
							)
						);
						return;
					}
					// Don't add outside nodes, they might not exist
					if(virtualNodeManager != sliver.manager)
						continue;
					
					if(virtualNodeManager == sliver.manager && rspec.type == Rspec.TYPE_MANIFEST)
					{
						// nodes from their manager's manifests without sliver_ids aren't in the sliver...
						if(sliverIdString.length == 0)
							continue;
						
						// component_id should always exist in the node's manager's manifest...
						if(componentIdString.length == 0)
						{
							afterError(
								new TaskError(
									"No Component ID set for node described as: " + nodeXml.toXMLString(),
									TaskError.CODE_PROBLEM
								)
							);
							return;
						}
					}
					
					var virtualNode:VirtualNode = sliver.slice.getByClientId(clientIdString);
					
					// Node not in the slice, need to add
					if(virtualNode == null)
					{
						virtualNode = new VirtualNode(sliver.slice, virtualNodeManager);
						sliver.slice.nodes.add(virtualNode);
					}
					else
						virtualNode.manager = virtualNodeManager;
					
					// Have the full info for this node
					if(markUnsubmitted)
						virtualNode.unsubmittedChanges = true;
					else if(virtualNodeManager == sliver.manager && rspec.type == Rspec.TYPE_MANIFEST)
						virtualNode.unsubmittedChanges = false;
					
					if(virtualNodeManager == sliver.manager && rspec.type == Rspec.TYPE_MANIFEST)
					{
						virtualNode.id = new IdnUrn(sliverIdString);
						virtualNode.manifest = nodeXml.toXMLString();
					}
					
					if(componentIdString.length > 0)
					{
						virtualNode.physicalId = new IdnUrn(componentIdString);
						if(virtualNode.Physical == null)
						{
							addMessage(
								"Physical Node with ID '"+componentIdString+"' was not found.",
								"Physical Node with ID '"+componentIdString+"' was not found.",
								LogMessage.LEVEL_WARNING
							);
							// If not looking for manifest info, don't care if exists
							// otherwise clear the component_id if not found
							if(rspec.type != Rspec.TYPE_MANIFEST)
								virtualNode.physicalId.full = "";
						}
					}
					
					virtualNode.clientId = clientIdString;
					
					// Deal with the attributes
					if(rspec.info.version < 1)
					{
						virtualNode.exclusive = String(nodeXml.@exclusive) == "1"
							|| String(nodeXml.@exclusive).toLowerCase() == "true";
						if(nodeXml.@sshdport.length() == 1) {
							if(virtualNode.services.loginServices == null)
								virtualNode.services.loginServices = new Vector.<LoginService>();
							if(virtualNode.services.loginServices.length == 0)
								virtualNode.services.loginServices.push(new LoginService());
							virtualNode.services.loginServices[0].port = String(nodeXml.@sshdport);
						}
						if(nodeXml.@hostname.length() == 1) {
							if(virtualNode.services.loginServices == null)
								virtualNode.services.loginServices = new Vector.<LoginService>();
							if(virtualNode.services.loginServices.length == 0)
								virtualNode.services.loginServices.push(new LoginService());
							virtualNode.services.loginServices[0].hostname = String(nodeXml.@hostname);
						}
						if(nodeXml.@tarfiles.length() == 1) {
							if(virtualNode.services.installServices == null)
								virtualNode.services.installServices = new Vector.<InstallService>();
							if(virtualNode.services.installServices.length == 0)
								virtualNode.services.installServices.push(new InstallService());
							virtualNode.services.installServices[0].url = String(nodeXml.@tarfiles);
						}
						if(nodeXml.@startup_command.length() == 1) {
							if(virtualNode.services.executeServices == null)
								virtualNode.services.executeServices = new Vector.<ExecuteService>();
							if(virtualNode.services.executeServices.length == 0)
								virtualNode.services.executeServices.push(new ExecuteService());
							virtualNode.services.executeServices[0].command = String(nodeXml.@startup_command);
						}
						if(nodeXml.@virtualization_type.length() == 1)
						{
							switch(String(nodeXml.@virtualization_type))
							{
								case SliverTypes.JUNIPER_LROUTER:
									virtualNode.sliverType.name = SliverTypes.JUNIPER_LROUTER;
									break;
								case SliverTypes.EMULAB_VNODE:
								default:
									if(nodeXml.@virtualization_subtype.length() == 1)
									{
										switch(String(nodeXml.@virtualization_type))
										{
											case SliverTypes.EMULAB_OPENVZ:
												virtualNode.sliverType.name = SliverTypes.EMULAB_OPENVZ;
												break;
											case SliverTypes.RAWPC_V1:
											default:
												virtualNode.sliverType.name = SliverTypes.RAWPC_V2;
												break;
										}
									}
									else
										virtualNode.sliverType.name = SliverTypes.RAWPC_V2;
									break;
							}
						}
					}
					else
					{
						virtualNode.exclusive = String(nodeXml.@exclusive) == "true" || String(nodeXml.@exclusive) == "1";
					}
					
					// Hack for INSTOOLS w/o namespace
					if(String(nodeXml.@MC) == "1")
					{
						virtualNode.mcInfo = new MCInfo();
						virtualNode.mcInfo.type = String(nodeXml.@mc_type);
					}
					
					// Get interfaces first
					var interfacesXmllist:XMLList = nodeXml.child(new QName(defaultNamespace, "interface"));
					for each(var interfaceXml:XML in interfacesXmllist)
					{
						var virtualInterfaceClientId:String = "";
						var virtualInterfaceSliverId:String = "";
						if(rspec.info.version < 1)
						{
							if(interfaceXml.@virtual_id.length() == 1)
								virtualInterfaceClientId = String(interfaceXml.@virtual_id);
							if(interfaceXml.@sliver_urn.length() == 1)
								virtualInterfaceSliverId = String(interfaceXml.@sliver_urn);
							else
							{
								// V1 didn't have sliver ids for interfaces...
								virtualInterfaceSliverId = IdnUrn.makeFrom(
									sliver.manager.id.authority,
									"interface",
									virtualInterfaceClientId).full;
							}
						}
						else
						{
							if(interfaceXml.@client_id.length() == 1)
								virtualInterfaceClientId = String(interfaceXml.@client_id);
							if(interfaceXml.@sliver_id.length() == 1)
								virtualInterfaceSliverId = String(interfaceXml.@sliver_id);
						}
						if(virtualInterfaceClientId.length == 0)
						{
							afterError(
								new TaskError(
									"No Client ID set on interface from node "+ virtualNode.clientId + ".",
									TaskError.CODE_PROBLEM
								)
							);
							return;
						}
						
						var virtualInterface:VirtualInterface = virtualNode.interfaces.getByClientId(virtualInterfaceClientId);
						
						if(rspec.type == Rspec.TYPE_MANIFEST
							&& virtualNode.manager == sliver.manager
							&& virtualInterfaceSliverId.length == 0)
						{
							// Interface not really used
							if(virtualInterface != null)
								virtualNode.interfaces.remove(virtualInterface);
							continue;
						}
						
						if(virtualInterface == null)
						{
							virtualInterface = new VirtualInterface(virtualNode);
							virtualNode.interfaces.add(virtualInterface);
						}
						virtualInterface.clientId = virtualInterfaceClientId;
						if(virtualInterfaceSliverId.length > 0)
							virtualInterface.id = new IdnUrn(virtualInterfaceSliverId);
						
						if(interfaceXml.@component_id.length() == 1 && IdnUrn.isIdnUrn(String(interfaceXml.@component_id)))
						{
							virtualInterface.physicalId = new IdnUrn(String(interfaceXml.@component_id));
							if(virtualInterface.Physical == null)
							{
								// Switched from error to warning
								addMessage(
									"Interface not found. Physical interface with ID '"+String(interfaceXml.@component_id)+"' was not found.",
									"Interface not found. Physical interface with ID '"+String(interfaceXml.@component_id)+"' was not found.",
									LogMessage.LEVEL_WARNING
								);
							}
						}
						
						if(rspec.info.version >= 2)
						{
							if(interfaceXml.@mac_address.length() == 1)
								virtualInterface.macAddress = String(interfaceXml.@mac_address);
							
							for each(var ipXml:XML in interfaceXml.children())
							{
								if(ipXml.localName() == "ip")
								{
									virtualInterface.ip.address = String(ipXml.@address);
									virtualInterface.ip.type = String(ipXml.@type);
									if(ipXml.@mask.length() == 1)
										virtualInterface.ip.netmask = String(ipXml.@mask);
									else if(ipXml.@netmask.length() == 1)
										virtualInterface.ip.netmask = String(ipXml.@netmask);
									if(virtualNode.manager == sliver.manager)
										virtualInterface.ip.extensions.buildFromOriginal(ipXml, [defaultNamespace.uri]);
								}
							}
						}
						if(virtualNode.manager == sliver.manager)
							virtualInterface.extensions.buildFromOriginal(interfaceXml, [defaultNamespace.uri]);
						interfacesById[virtualInterface.clientId] = virtualInterface;
						if(virtualInterface.id.full.length > 0)
							interfacesById[virtualInterface.id.full] = virtualInterface;
					}
					
					// go through the other children
					for each(var nodeChildXml:XML in nodeXml.children())
					{
						localName = nodeChildXml.localName();
						// default namespace stuff
						if(nodeChildXml.namespace() == defaultNamespace)
						{
							switch(localName)
							{
								case "disk_image":
									var diskImageV1Name:String = String(nodeChildXml.@name);
									var diskImageV1:DiskImage = new DiskImage(diskImageV1Name);//sliver.manager.diskImages.getByLongId(diskImageV1Name);
									diskImageV1.extensions.buildFromOriginal(nodeChildXml, [defaultNamespace.uri]);
									virtualNode.sliverType.selectedImage = diskImageV1;
									break;
								case "node_type":
									virtualNode.hardwareType = new HardwareType(String(nodeChildXml.@type_name), Number(nodeChildXml.@type_slots));
									// Hack for if subvirtualization_type isn't set...
									if(virtualNode.hardwareType.name == "pcvm")
										virtualNode.sliverType.name = SliverTypes.EMULAB_OPENVZ;
									break;
								case "hardware_type":
									virtualNode.hardwareType = new HardwareType(String(nodeChildXml.@name));
									var emulabNodeTypes:XMLList = nodeChildXml.child(new QName(RspecUtil.emulabNamespace, "node_type"));
									if(emulabNodeTypes.length() == 1)
										virtualNode.hardwareType.slots = Number(emulabNodeTypes[0].@type_slots);
									break;
								case "sliver_type":
									virtualNode.sliverType.name = String(nodeChildXml.@name);
									for each(var sliverTypeChild:XML in nodeChildXml.children())
									{
										if(sliverTypeChild.namespace() == defaultNamespace)
										{
											if(sliverTypeChild.localName() == "disk_image")
											{
												var diskImageV2Name:String = String(sliverTypeChild.@name);
												var diskImageV2:DiskImage = new DiskImage(diskImageV2Name);//sliver.manager.diskImages.getByLongId(diskImageV2Name);
												diskImageV2.extensions.buildFromOriginal(sliverTypeChild, [defaultNamespace.uri]);
												virtualNode.sliverType.selectedImage = diskImageV2;
											}
										}
										else
										{
											if(sliverTypeChild.namespace() == RspecUtil.delayNamespace)
											{
												if(sliverTypeChild.localName() == "sliver_type_shaping")
												{
													virtualNode.sliverType.pipes = new PipeCollection();
													for each(var pipeXml:XML in sliverTypeChild.children())
													{
														virtualNode.sliverType.pipes.add(
															new Pipe(
																virtualNode.interfaces.getByClientId(String(pipeXml.@source)),
																virtualNode.interfaces.getByClientId(String(pipeXml.@dest)),
																pipeXml.@capacity.length() == 1 ? Number(pipeXml.@capacity) : NaN,
																pipeXml.@latency.length() == 1 ? Number(pipeXml.@latency) : NaN,
																pipeXml.@packet_loss.length() == 1 ? Number(pipeXml.@packet_loss) : NaN
															)
														);
													}
												}
											}
											else if(sliverTypeChild.namespace() == RspecUtil.planetlabNamespace)
											{
												if(sliverTypeChild.localName() == "initscript")
												{
													virtualNode.sliverType.selectedPlanetLabInitscript = String(sliverTypeChild.@name);
												}
												
											}
											else if(sliverTypeChild.namespace() == RspecUtil.firewallNamespace)
											{
												if(sliverTypeChild.localName() == "firewall_config")
												{
													virtualNode.sliverType.firewallStyle = String(sliverTypeChild.@style);
													virtualNode.sliverType.firewallType = String(sliverTypeChild.@type);
												}
												
											}
										}
									}
									if(virtualNode.manager == sliver.manager)
										virtualNode.sliverType.extensions.buildFromOriginal(nodeChildXml, [defaultNamespace.uri, RspecUtil.delayNamespace.uri, RspecUtil.planetlabNamespace.uri]);
									break;
								case "services":
									if(virtualNode.manager == sliver.manager)
									{
										if(rspec.info.version >= 2)
											virtualNode.services = new Services();
										for each(var servicesChild:XML in nodeChildXml.children())
										{
											if(servicesChild.localName() == "login")
											{
												if(parseManifest)
												{
													if(virtualNode.services.loginServices == null)
														virtualNode.services.loginServices = new Vector.<LoginService>();
													
													var loginService:LoginService =
														new LoginService(
															String(servicesChild.@authentication),
															String(servicesChild.@hostname),
															String(servicesChild.@port),
															String(servicesChild.@username)
														);
													if(rspec.info.version < 1)
													{
														if(virtualNode.services.loginServices.length == 1)
														{
															virtualNode.services.loginServices[0].authentication = loginService.authentication;
															virtualNode.services.loginServices[0].hostname = loginService.hostname;
															virtualNode.services.loginServices[0].port = loginService.port;
															virtualNode.services.loginServices[0].username = loginService.username;
														}
														else
															virtualNode.services.loginServices.push(loginService);
													}
													else
													{
														loginService.extensions.buildFromOriginal(servicesChild, [defaultNamespace.uri]);
														virtualNode.services.loginServices.push(loginService);
													}
												}
											}
											else if(servicesChild.localName() == "install")
											{
												var newInstall:InstallService =
													new InstallService(
														String(servicesChild.@url),
														String(servicesChild.@install_path),
														String(servicesChild.@file_type)
													);
												newInstall.extensions.buildFromOriginal(servicesChild, [defaultNamespace.uri]);
												if(virtualNode.services.installServices == null)
													virtualNode.services.installServices = new Vector.<InstallService>();
												virtualNode.services.installServices.push(newInstall);
											}
											else if(servicesChild.localName() == "execute")
											{
												var newExecute:ExecuteService = 
													new ExecuteService(
														String(servicesChild.@command),
														String(servicesChild.@shell)
													);
												newExecute.extensions.buildFromOriginal(servicesChild, [defaultNamespace.uri]);
												if(virtualNode.services.executeServices == null)
													virtualNode.services.executeServices = new Vector.<ExecuteService>();
												virtualNode.services.executeServices.push(newExecute);
											}
										}
										virtualNode.services.extensions.buildFromOriginal(nodeChildXml, [defaultNamespace.uri]);
									}
									break;
								case "host":
									if(parseManifest)
									{
										virtualNode.host = new Host(String(nodeChildXml.@name));
										if(virtualNode.manager == sliver.manager)
											virtualNode.host.extensions.buildFromOriginal(nodeChildXml, [defaultNamespace.uri]);
									}
									break;
							}
						}
						// Extension stuff
						else
						{
							if(nodeChildXml.namespace() == RspecUtil.flackNamespace)
							{
								virtualNode.flackInfo.x = int(nodeChildXml.@x);
								virtualNode.flackInfo.y = int(nodeChildXml.@y);
								if(nodeChildXml.@unbound.length() == 1)
								{
									virtualNode.flackInfo.unbound = String(nodeChildXml.@unbound).toLowerCase() == "true" || String(nodeChildXml.@unbound) == "1";
									if(virtualNode.flackInfo.unbound && !parseManifest)
										virtualNode.physicalId.full = "";
								}
							}
						}
					}
					
					nodesById[virtualNode.clientId] = virtualNode;
					
					if(virtualNode.manager == sliver.manager)
					{
						virtualNode.extensions.buildFromOriginal(
							nodeXml,
							[
								defaultNamespace.uri,
								RspecUtil.flackNamespace.uri
							]
						);
					}
				}
				
				for each(var checkVirtualNodeForParent:VirtualNode in sliver.slice.nodes.getByManager(sliver.manager).collection)
				{
					if(checkVirtualNodeForParent.Physical != null && checkVirtualNodeForParent.Physical.subNodeOf != null)
					{
						var superNodes:VirtualNodeCollection = sliver.slice.nodes.getBoundTo(checkVirtualNodeForParent.Physical.subNodeOf);
						if(superNodes.length > 0)
						{
							checkVirtualNodeForParent.superNode = superNodes.collection[0];
							if(checkVirtualNodeForParent.superNode.subNodes == null)
								checkVirtualNodeForParent.superNode.subNodes = new VirtualNodeCollection();
							if(!checkVirtualNodeForParent.superNode.subNodes.contains(checkVirtualNodeForParent))
								checkVirtualNodeForParent.superNode.subNodes.add(checkVirtualNodeForParent);
						}
						else
						{
							checkVirtualNodeForParent.superNode = null;
						}
					}
				}
				
				for each(var linkXml:XML in xmlDocument.defaultNamespace::link)
				{
					var virtualLinkClientIdString:String = "";
					var virtualLinkSliverIdString:String = "";
					if(rspec.info.version < 1)
					{
						virtualLinkSliverIdString = String(linkXml.@sliver_urn);
						virtualLinkClientIdString = String(linkXml.@virtual_id);
					}
					else
					{
						virtualLinkSliverIdString = String(linkXml.@sliver_id);
						virtualLinkClientIdString = String(linkXml.@client_id);
					}
					
					var virtualLink:VirtualLink = sliver.slice.links.getByClientId(virtualLinkClientIdString);
					if(virtualLink == null)
						virtualLink = new VirtualLink(sliver.slice);
					virtualLink.id = new IdnUrn(virtualLinkSliverIdString);
					virtualLink.clientId = virtualLinkClientIdString;
					
					// Get interfaces first, make sure this is valid
					var interfaceRefsXmllist:XMLList = linkXml.child(new QName(defaultNamespace, "interface_ref"));
					
					var skip:Boolean = false;
					for each(var interfaceRefXml:XML in interfaceRefsXmllist)
					{
						var referencedInterfaceClientId:String = "";
						var interfacedInterface:VirtualInterface = null;
						if(rspec.info.version < 1)
						{
							referencedInterfaceClientId = String(interfaceRefXml.@virtual_interface_id);
							// Hack if virtual_interface_id isn't global...
							var referencedNodeClientId:String = String(interfaceRefXml.@virtual_node_id);
							if(referencedNodeClientId.length > 0)
							{
								var interfacedNode:VirtualNode = sliver.slice.nodes.getByClientId(referencedNodeClientId);
								if(interfacedNode != null)
								{
									interfacedInterface = interfacedNode.interfaces.getByClientId(referencedInterfaceClientId);
									if(referencedInterfaceClientId == "control" && interfacedInterface == null)
									{
										interfacedInterface = new VirtualInterface(interfacedNode, "control");
										interfacedNode.interfaces.add(interfacedInterface);
									}
								}
							}
							else
								interfacedInterface = sliver.slice.nodes.getInterfaceByClientId(referencedInterfaceClientId);
						}
						else
						{
							referencedInterfaceClientId = String(interfaceRefXml.@client_id);
							interfacedInterface = sliver.slice.nodes.getInterfaceByClientId(referencedInterfaceClientId);
						}
						
						if(interfacedInterface == null)
						{
							addMessage(
								"Interface not found",
								"Interface not found. Interface with client ID '"+referencedInterfaceClientId+"' was not found.",
								LogMessage.LEVEL_WARNING
							);
							skip = true;
							break;
						}
						
						var interfacedInterfaceReference:VirtualInterfaceReference = virtualLink.interfaceRefs.getReferenceFor(interfacedInterface);
						if(interfacedInterfaceReference == null)
						{
							interfacedInterfaceReference = new VirtualInterfaceReference(interfacedInterface);
							virtualLink.interfaceRefs.add(interfacedInterfaceReference);
						}
						
						if(interfacedInterface.Owner.manager == sliver.manager)
							interfacedInterfaceReference.extensions.buildFromOriginal(interfaceRefXml, [defaultNamespace.uri]);
						
						if(rspec.info.version < 1)
						{
							if(interfaceRefXml.@tunnel_ip.length() == 1)
								interfacedInterface.ip = new Ip(String(interfaceRefXml.@tunnel_ip));
							else if(interfaceRefXml.@IP.length() == 1)
								interfacedInterface.ip = new Ip(String(interfaceRefXml.@IP));
							if(interfaceRefXml.@netmask.length() == 1)
								interfacedInterface.ip.netmask = String(interfaceRefXml.@netmask);
							if(interfaceRefXml.@sliver_urn.length() == 1)
								interfacedInterface.id = new IdnUrn(interfaceRefXml.@sliver_urn);
							if(interfaceRefXml.@component_urn.length() == 1)
								interfacedInterface.physicalId = new IdnUrn(interfaceRefXml.@component_urn);
						}
						else
						{
							if(interfaceRefXml.@sliver_id.length() == 1)
								interfacedInterface.id = new IdnUrn(interfaceRefXml.@sliver_id);
							if(interfaceRefXml.@component_id.length() == 1)
							{
								interfacedInterface.physicalId = new IdnUrn(String(interfaceRefXml.@component_id));
								if(interfacedInterface.Physical == null)
								{
									// Switched from error to warning
									addMessage(
										"Interface not found. Physical interface with ID '"+String(interfaceRefXml.@component_id)+"' was not found.",
										"Interface not found. Physical interface with ID '"+String(interfaceRefXml.@component_id)+"' was not found.",
										LogMessage.LEVEL_WARNING
									);
								}
							}
						}
					}
					
					if(skip)
					{
						addMessage(
							"Skipping link",
							"Skipping link due to errors, possibly due to another RSPEC having not been parsed yet.",
							LogMessage.LEVEL_WARNING
						);
						continue;
					}
					
					if(!sliver.slice.links.contains(virtualLink))
						sliver.slice.links.add(virtualLink);
					
					// Add the link to the interfaces
					for each(var myInterface:VirtualInterface in virtualLink.interfaceRefs.Interfaces.collection)
					{
						if(!myInterface.links.contains(virtualLink))
							myInterface.links.add(virtualLink);
					}
					
					if(rspec.info.version < 1)
					{
						virtualLink.type.name = String(linkXml.@link_type).toLowerCase();
						switch(virtualLink.type.name)
						{
							case LinkType.GRETUNNEL_V1:
								virtualLink.type.name = LinkType.GRETUNNEL_V2;
								break;
							case LinkType.LAN_V1:
								virtualLink.type.name = LinkType.LAN_V2;
						}
					}
					else
					{
						if(linkXml.@vlantag.length() == 1)
							virtualLink.vlantag = String(linkXml.@vlantag);
					}
					
					for each(var linkChildXml:XML in linkXml.children())
					{
						localName = linkChildXml.localName();
						// default namespace stuff
						if(linkChildXml.namespace() == defaultNamespace)
						{
							switch(localName)
							{
								case "bandwidth":
									virtualLink.Capacity = Number(linkChildXml.toString());
									break;
								case "latency":
									virtualLink.Latency = Number(linkChildXml.toString());
									break;
								case "packet_loss":
									virtualLink.PacketLoss = Number(linkChildXml.toString());
									break;
								case "property":
									var sourceInterface:VirtualInterface = sliver.slice.nodes.getInterfaceByClientId(linkChildXml.@source_id);
									var destInterface:VirtualInterface = sliver.slice.nodes.getInterfaceByClientId(linkChildXml.@dest_id);
									var newProperty:Property = virtualLink.properties.getFor(sourceInterface, destInterface);
									if(newProperty == null)
									{
										newProperty = new Property(sourceInterface, destInterface);
										virtualLink.properties.add(newProperty);
									}
									
									if(linkChildXml.@capacity.length() == 1)
										newProperty.capacity = Number(linkChildXml.@capacity);
									if(linkChildXml.@latency.length() == 1)
										newProperty.latency = Number(linkChildXml.@latency);
									if(linkChildXml.@packet_loss.length() == 1)
										newProperty.packetLoss = Number(linkChildXml.@packet_loss);
									newProperty.extensions.buildFromOriginal(linkChildXml, [defaultNamespace.uri]);
									break;
								case "component_hop":
									// XXX implement correctly...
									var testString:String = linkChildXml.toXMLString();
									if(testString.indexOf("gpeni") != -1)
										virtualLink.type.name = LinkType.GPENI;
									else if(testString.indexOf("ion") != -1)
										virtualLink.type.name = LinkType.ION;
									break;
								case "link_type":
									if(linkChildXml.@name.length() == 1)
										virtualLink.type.name = String(linkChildXml.@name).toLowerCase();
									else if(linkChildXml.@type_name.length() == 1)
										virtualLink.type.name = String(linkChildXml.@type_name).toLowerCase();
									switch(virtualLink.type.name)
									{
										case LinkType.GRETUNNEL_V1:
											virtualLink.type.name = LinkType.GRETUNNEL_V2;
										case LinkType.LAN_V1:
											virtualLink.type.name = LinkType.LAN_V2;
									}
									virtualLink.type.extensions.buildFromOriginal(linkChildXml, [defaultNamespace.uri]);
									break;
								case "component_manager":
									if(linkChildXml.@name == sliver.manager.id.full)
									{
										var managerReference:GeniManagerReference = virtualLink.managerRefs.getReferenceFor(sliver.manager);
										if(managerReference == null)
										{
											managerReference = new GeniManagerReference(sliver.manager);
											virtualLink.managerRefs.add(managerReference);
										}
										managerReference.extensions.buildFromOriginal(linkChildXml, [defaultNamespace.uri]);
									}
									break;
							}
						}
					}
					
					// Make sure links between managers aren't normal
					if(virtualLink.interfaceRefs.Interfaces.Managers.length > 1 && virtualLink.type.name == LinkType.LAN_V2)
						virtualLink.type.name = LinkType.GRETUNNEL_V2;
					
					virtualLink.extensions.buildFromOriginal(linkXml, [defaultNamespace.uri]);
					
					// detect that the link has been entirely created before setting the manifest
					var isManifestFinished:Boolean = rspec.type == Rspec.TYPE_MANIFEST;
					/*for each(var testInterface:VirtualInterface in virtualLink.interfaceRefs.Interfaces.collection)
					{
						if(testInterface.Physical == null)
						{
							isManifestFinished = false;
							break;
						}
					}*/
					
					if(markUnsubmitted)
						virtualLink.unsubmittedChanges = true;
					else if(isManifestFinished)
						virtualLink.unsubmittedChanges = false;
					
					if(isManifestFinished)
						virtualLink.manifest = linkXml.toXMLString();
				}
				
				// Client extension
				var clientSliceInfo:XMLList = xmlDocument.child(new QName(RspecUtil.clientNamespace, "client_info"));
				if(clientSliceInfo.length() == 1)
				{
					var clientSliceInfoXml:XML = clientSliceInfo[0];
					sliver.slice.clientInfo.name = clientSliceInfoXml.@name;
					sliver.slice.clientInfo.version = clientSliceInfoXml.@version;
					sliver.slice.clientInfo.environment = clientSliceInfoXml.@description;
					sliver.slice.clientInfo.url = clientSliceInfoXml.@url;
				}
				
				// History extension
				var sliceHistory:XMLList = xmlDocument.child(new QName(RspecUtil.historyNamespace, "slice_history"));
				sliver.slice.history = new SliceHistory();
				if(sliceHistory.length() == 1)
				{
					sliver.slice.history.backIndex = int((sliceHistory[0] as XML).@backIndex);
					sliver.slice.history.stateName = String((sliceHistory[0] as XML).@note);
					var statesXml:XMLList = (sliceHistory[0] as XML).children();
					for each(var stateXml:XML in statesXml)
						sliver.slice.history.states.push(new SliceHistoryItem(CompressUtil.uncompress(stateXml.toString()), String(stateXml.@note)));
				}
				
				// Flack extension
				var sliceFlackInfoXml:XMLList = xmlDocument.child(new QName(RspecUtil.flackNamespace, "slice_info"));
				sliver.slice.flackInfo = new SliceFlackInfo();
				if(sliceFlackInfoXml.length() == 1)
				{
					sliver.slice.flackInfo.view = String(sliceFlackInfoXml[0].@view);
				}
				
				// Make sure the sliver is saved in the slice if resources were found
				if(sliver.slice.nodes.getByManager(sliver.manager).length > 0
					&& !sliver.slice.slivers.contains(sliver))
				{
					sliver.slice.slivers.add(sliver);
				}
				
				if(markUnsubmitted)
					sliver.UnsubmittedChanges = true;
				else if(rspec.type == Rspec.TYPE_MANIFEST)
						sliver.UnsubmittedChanges = false;
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLIVER,
					sliver,
					FlackEvent.ACTION_POPULATED
				);
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					sliver.slice,
					FlackEvent.ACTION_POPULATING
				);
				
				addMessage(
					"Parsed",
					sliver.manager.hrn +
						"\n" + rspec.info.toString() +
						"\nNodes from sliver: " + sliver.slice.nodes.getByManager(sliver.manager).length +
						"\nLinks from sliver: " + sliver.slice.links.getConnectedToManager(sliver.manager).length,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				super.afterComplete(false);
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
	}
}