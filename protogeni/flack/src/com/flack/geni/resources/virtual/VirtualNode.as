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

package com.flack.geni.resources.virtual
{
	import com.flack.geni.RspecUtil;
	import com.flack.geni.resources.DiskImage;
	import com.flack.geni.resources.SliverType;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.physical.HardwareType;
	import com.flack.geni.resources.physical.PhysicalInterface;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.extensions.NodeFlackInfo;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.utils.StringUtil;

	/**
	 * Resource within a slice
	 * 
	 * @author mstrum
	 * 
	 */
	public class VirtualNode extends VirtualComponent
	{
		public var physicalId:IdnUrn = new IdnUrn();
		public function get Physical():PhysicalNode
		{
			if(physicalId.full.length > 0)
				return manager.nodes.getById(physicalId.full);
			else
				return null;
		}
		public function set Physical(newPhysicalNode:PhysicalNode):void
		{
			if(newPhysicalNode == null)
			{
				physicalId = new IdnUrn();
				return;
			}
			physicalId = new IdnUrn(newPhysicalNode.id.full);
			
			manager = newPhysicalNode.manager as GeniManager;
			exclusive = newPhysicalNode.exclusive;
			if(clientId.length == 0)
			{
				if(slice.isIdUnique(this, newPhysicalNode.name))
					clientId = newPhysicalNode.name;
				else
					clientId = slice.getUniqueId(this, newPhysicalNode.name+"-");
			}
			
			if(newPhysicalNode.sliverTypes.length == 1)
			{
				sliverType.name = newPhysicalNode.sliverTypes.collection[0].name;
				sliverType.diskImages = newPhysicalNode.sliverTypes.collection[0].diskImages;
			}
			else
			{
				if(newPhysicalNode.exclusive)
				{
					if(newPhysicalNode.sliverTypes.getByName(SliverTypes.RAWPC_V2) != null)
					{
						sliverType.name = SliverTypes.RAWPC_V2;
						sliverType.diskImages = newPhysicalNode.sliverTypes.getByName(SliverTypes.RAWPC_V2).diskImages;
					}
				}
				else
				{
					if(newPhysicalNode.sliverTypes.getByName(SliverTypes.EMULAB_OPENVZ) != null)
					{
						sliverType.name = SliverTypes.EMULAB_OPENVZ;
						sliverType.diskImages = newPhysicalNode.sliverTypes.getByName(SliverTypes.EMULAB_OPENVZ).diskImages;
					}
				}
			}
			unsubmittedChanges = true;
		}
		public function get Bound():Boolean
		{
			return physicalId.full.length > 0;
		}
		
		public var exclusive:Boolean;
		public function get Vm():Boolean
		{
			return hardwareType.name.indexOf("vm") > -1
				|| (Physical != null && !Physical.exclusive)
				|| SliverTypes.isVm(sliverType.name);
		}
		
		public var superNode:VirtualNode;
		public var subNodes:VirtualNodeCollection;
		
		public var manager:GeniManager;
		
		[Bindable]
		public var interfaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
		public function get HasUsableExperimentalInterface():Boolean
		{
			if(!Bound || Physical == null)
				return true;
			
			if(sliverType.name == SliverTypes.JUNIPER_LROUTER)
				return true;
			
			for each (var candidate:PhysicalInterface in Physical.interfaces.collection)
			{
				if (candidate.role != PhysicalInterface.ROLE_CONTROL)
				{
					// Use if not bound already
					if(slice.nodes.getInterfaceBoundTo(candidate) == null)
						return true;
				}
			}
			return false;
		}
		
		public var host:Host = new Host();
		
		// Sliver
		[Bindable]
		public var sliverType:SliverType;
		
		// Capabilities
		public var hardwareType:HardwareType = new HardwareType();
		
		// Services
		public var services:Services = new Services();
		
		// Flack extension
		public var flackInfo:NodeFlackInfo = new NodeFlackInfo();
		
		/**
		 * 
		 * @param newSlice Slice of the node
		 * @param owner Manager where the node is located
		 * @param newName Name
		 * @param newExclusive Exclusivity
		 * @param newSliverType Sliver type
		 * 
		 */
		public function VirtualNode(newSlice:Slice,
									owner:GeniManager = null,
									newName:String = "",
									newExclusive:Boolean = true,
									newSliverType:String = "")
		{
			super(newSlice, newName);
			
			manager = owner;
			sliverType = new SliverType(newSliverType);
			exclusive = newExclusive;
		}
		
		public function allocateExperimentalInterface():VirtualInterface
		{
			if(!Bound || Physical == null || sliverType.name == SliverTypes.JUNIPER_LROUTER)
				return new VirtualInterface(this);
			else
			{
				for each (var candidate:PhysicalInterface in Physical.interfaces.collection)
				{
					if (candidate.role == PhysicalInterface.ROLE_EXPERIMENTAL)
					{
						// Use if not bound already
						if(slice.nodes.getInterfaceBoundTo(candidate) == null)
						{
							var newPhysicalInterface:VirtualInterface = new VirtualInterface(this);
							newPhysicalInterface.Physical = candidate;
							return newPhysicalInterface;
						}
					}
				}
			}
			return null;
		}
		
		/**
		 * Removes pipes not needed or adds missing pipes. Safe for any node type to call.
		 * 
		 */
		public function cleanupPipes():void
		{
			if(sliverType.name == SliverTypes.DELAY)
			{
				if(sliverType.pipes == null)
					sliverType.pipes = new PipeCollection();
				var i:int;
				// Make sure we have pipes for all interfaces
				for(i = 0; i < interfaces.length; i++)
				{
					var first:VirtualInterface = interfaces.collection[i];
					for(var j:int = i+1; j < interfaces.length; j++)
					{
						var second:VirtualInterface = interfaces.collection[j];
						
						var firstPipe:Pipe = sliverType.pipes.getFor(first, second);
						if(firstPipe == null)
						{
							firstPipe = new Pipe(first, second, Math.min(first.capacity, second.capacity));
							sliverType.pipes.add(firstPipe);
							unsubmittedChanges = true;
						}
						
						var secondPipe:Pipe = sliverType.pipes.getFor(second, first);
						if(secondPipe == null)
						{
							secondPipe = new Pipe(second, first, Math.min(first.capacity, second.capacity));
							sliverType.pipes.add(secondPipe);
							unsubmittedChanges = true;
						}
					}
				}
				
				// Remove pipes for interfaces which don't exist
				for(i = 0; i < sliverType.pipes.length; i++)
				{
					var pipe:Pipe = sliverType.pipes.collection[i];
					if(!interfaces.contains(pipe.src) || !interfaces.contains(pipe.dst))
					{
						sliverType.pipes.remove(pipe);
						unsubmittedChanges = true;
						i--;
					}
				}
			}
			else
			{
				if(sliverType.pipes != null && sliverType.pipes.length > 0)
					unsubmittedChanges = true;
				sliverType.pipes = null;
			}
		}
		
		public function switchTo(newManager:GeniManager):void
		{
			if(newManager == manager)
				return;
			if(manager == null)
			{
				manager = newManager;
				return;
			}
			var newSliver:Sliver = slice.slivers.getOrCreateByManager(newManager, slice);
			var oldSliver:Sliver = slice.slivers.getOrCreateByManager(manager, slice);
			var oldManager:GeniManager = manager;
			manager = newManager;
			oldSliver.UnsubmittedChanges = true;
			
			for each(var vi:VirtualInterface in interfaces.collection)
			{
				for each(var vl:VirtualLink in vi.links.collection)
				{
					// See if we need to change the link due to the manager change
					for each(var otherInterface:VirtualInterface in vl.interfaceRefs.Interfaces.collection)
					{
						if(otherInterface != vi)
						{
							// Now will be links to another manager
							if(otherInterface._owner.manager == oldManager)
							{
								vl.setUpTunnels();
								break;
							}
							// Now the same manager
							else if(otherInterface._owner.manager == manager)
							{
								vl.type.name = LinkType.LAN_V2;
								break;
							}
							// Otherwise still different managers, no changes needed
						}
					}
				}
			}
		}
		
		public function removeFromSlice():void
		{
			// Remove subnodes
			if(subNodes != null)
			{
				for each(var sub:VirtualNode in subNodes.collection)
					sub.removeFromSlice();
			}
				
			// Remove connections with links
			while(interfaces.length > 0)
			{
				var iface:VirtualInterface = interfaces.collection[0];
				while(iface.links.length > 0)
				{
					var removeLink:VirtualLink = iface.links.collection[0];
					removeLink.removeInterface(iface);
					if(removeLink.interfaceRefs.length <= 1)
						removeLink.removeFromSlice();
				}
				interfaces.remove(iface);
			}
			
			var sliver:Sliver = slice.slivers.getOrCreateByManager(manager, slice);
			if(sliver.Created)
				sliver.UnsubmittedChanges = true;
			
			slice.nodes.remove(this);
			
			if(!sliver.Created && sliver.Nodes.length == 0)
				sliver.removeFromSlice();
		}
		
		public function UnboundCloneFor(newSlice:Slice):VirtualNode
		{
			var newClone:VirtualNode = new VirtualNode(newSlice, manager, "", exclusive, sliverType.name);
			if(!newClone.flackInfo.unbound)
			{
				if(Vm)
					newClone.physicalId.full = physicalId.full;
			}
			if(newSlice.isIdUnique(newClone, clientId))
				newClone.clientId = clientId;
			else
				newClone.clientId = newClone.slice.getUniqueId(newClone, StringUtil.makeSureEndsWith(clientId,"-"));
			if(sliverType.selectedImage != null)
				newClone.sliverType.selectedImage = new DiskImage(sliverType.selectedImage.id.full);
			newClone.sliverType.diskImages = sliverType.diskImages;
			newClone.sliverType.extensions = sliverType.extensions.Clone;
			newClone.sliverType.selectedPlanetLabInitscript = sliverType.selectedPlanetLabInitscript;
			newClone.sliverType.firewallStyle = sliverType.firewallStyle;
			newClone.sliverType.firewallType = sliverType.firewallType;
			if(hardwareType.name.length > 0)
			{
				newClone.hardwareType.name = hardwareType.name;
				newClone.hardwareType.slots = hardwareType.slots;
			}
			for each(var executeService:ExecuteService in services.executeServices)
			{
				var newExecute:ExecuteService = new ExecuteService(executeService.command, executeService.shell);
				newExecute.extensions = executeService.extensions.Clone;
				newClone.services.executeServices.push(newExecute);
			}
			for each(var installService:InstallService in services.installServices)
			{
				var newInstall:InstallService = new InstallService(installService.url, installService.installPath, installService.fileType);
				newInstall.extensions = installService.extensions.Clone;
				newClone.services.installServices.push(newInstall);
			}
			newClone.extensions = extensions.Clone;
			// Remove the emulab extensions, it's just manifest stuff
			if(newClone.extensions.spaces != null)
			{
				for(var i:int = 0; i < newClone.extensions.spaces.length; i++)
				{
					if(newClone.extensions.spaces.collection[i].namespace.uri == RspecUtil.emulabNamespace.uri)
					{
						newClone.extensions.spaces.remove(newClone.extensions.spaces.collection[i]);
						i--;
					}
				}
			}
			return newClone;
		}
		
		override public function toString():String
		{
			var result:String = "[VirtualNode "+StringProperties
				+",\n\t\tClientID="+clientId
				+",\n\t\tComponentID="+(Bound ? Physical.id.full : "")
				+",\n\t\tExclusive="+exclusive
				+",\n\t\tManagerID="+manager.id.full
				+",\n\t\tHost="+host.name
				+",\n\t\tSliverType="+sliverType.name
				+",\n\t\tDiskImage="+(sliverType.selectedImage != null ? sliverType.selectedImage.id.full : "")
				+",\n\t\tHardwareType="+hardwareType
				+",\n\t\tFlackX="+flackInfo.x
				+",\n\t\tFlackY="+flackInfo.y
				+",\n\t\tFlackUnbound="+flackInfo.unbound
				+",\n\t\t]";
			// XXX Services
			if(interfaces.length > 0)
			{
				result += "\n\t[Interfaces]";
				for each(var iface:VirtualInterface in interfaces.collection)
				result += "\n\t\t"+iface.toString();
				result += "\n\t[/Interfaces]";
			}
			return result + "\n\t[/VirtualNode]";
		}
	}
}