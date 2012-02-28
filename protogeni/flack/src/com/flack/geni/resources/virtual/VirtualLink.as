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
	import com.flack.geni.resources.Property;
	import com.flack.geni.resources.PropertyCollection;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.sites.GeniManager;

	/**
	 * Link between resources within a slice
	 * 
	 * @author mstrum
	 * 
	 */
	public class VirtualLink extends VirtualComponent
	{
		[Bindable]
		public var interfaceRefs:VirtualInterfaceReferenceCollection = new VirtualInterfaceReferenceCollection();
		
		public var managerRefs:GeniManagerReferenceCollection = new GeniManagerReferenceCollection();
		
		public var type:LinkType = new LinkType();
		
		public var vlantag:String = "";
		
		public var properties:PropertyCollection = new PropertyCollection();
		
		/**
		 * Capacity (kbs)
		 */
		private var _capacity:Number = NaN;
		/**
		 * 
		 * @param value Capacity (kbs)
		 * 
		 */
		public function set Capacity(value:Number):void
		{
			setUpProperties();
			for each(var property:Property in properties.collection)
				property.capacity = value;
			_capacity = value;
		}
		/**
		 * 
		 * @return Capacity (kbs)
		 * 
		 */
		public function get Capacity():Number
		{
			var maxCapacity:Number = 0;
			for each(var property:Property in properties.collection)
			{
				if(property.capacity && property.capacity > maxCapacity)
					maxCapacity = property.capacity;
			}
			return maxCapacity;
		}
		
		/**
		 * Packet loss (X/1)
		 */
		private var _packetLoss:Number = NaN;
		/**
		 * 
		 * @param value Packet loss (X/1)
		 * 
		 */
		public function set PacketLoss(value:Number):void
		{
			setUpProperties();
			for each(var property:Property in properties.collection)
				property.packetLoss = value;
			_packetLoss = value;
		}
		/**
		 * 
		 * @return Packet loss (X/1)
		 * 
		 */
		public function get PacketLoss():Number
		{
			var maxPacketLoss:Number = 0;
			for each(var property:Property in properties.collection)
			{
				if(property.packetLoss && property.packetLoss > maxPacketLoss)
					maxPacketLoss = property.packetLoss;
			}
			return maxPacketLoss;
		}
		
		/**
		 * Latency (ms)
		 */
		private var _latency:Number = NaN;
		/**
		 * 
		 * @param value Latency (ms)
		 * 
		 */
		public function set Latency(value:Number):void
		{
			setUpProperties();
			for each(var property:Property in properties.collection)
				property.latency = value;
			_latency = value;
		}
		/**
		 * 
		 * @return Latency (ms)
		 * 
		 */
		public function get Latency():Number
		{
			var maxLatency:Number = 0;
			for each(var property:Property in properties.collection)
			{
				if(property.latency && property.latency > maxLatency)
					maxLatency = property.latency;
			}
			return maxLatency;
		}
		
		/**
		 * 
		 * @param newSlice Slice where the link is located
		 * 
		 */
		public function VirtualLink(newSlice:Slice)
		{
			super(newSlice);
		}
		
		/**
		 * 
		 * @return TRUE if link is one-way
		 * 
		 */
		public function get Simplex():Boolean
		{
			if(interfaceRefs.length == 2)
			{
				return (interfaceRefs.collection[0].referencedInterface.capacity == 0 && interfaceRefs.collection[1].referencedInterface.capacity != 0)
					|| (interfaceRefs.collection[1].referencedInterface.capacity == 0 && interfaceRefs.collection[0].referencedInterface.capacity != 0);
			}
			return false;
		}
		
		/**
		 * 
		 * @return TRUE if link is two-way
		 * 
		 */
		public function get Duplex():Boolean
		{
			if(interfaceRefs.length == 2)
			{
				return interfaceRefs.collection[0].referencedInterface.capacity != 0
					&& interfaceRefs.collection[0].referencedInterface.capacity == interfaceRefs.collection[1].referencedInterface.capacity;
			}
			return false;
		}
		
		/**
		 * 
		 * @return TRUE if LAN
		 * 
		 */
		public function get Lan():Boolean
		{
			return interfaceRefs.length > 2;
		}
		
		/**
		 * 
		 * @param nodes Nodes wanting to create link for
		 * @return TRUE if link can be made
		 * 
		 */
		public function canEstablish(nodes:VirtualNodeCollection):Boolean
		{
			// Needs to connect at least two nodes
			if(nodes == null || nodes.collection.length < 2)
				return false;
			
			// Try to allocate interfaces needed
			for each(var connectedNode:VirtualNode in nodes.collection)
			{
				if(connectedNode.allocateExperimentalInterface() == null)
					return false;
			}
			
			return true;
		}
		
		/**
		 * 
		 * @param nodes Nodes wanting to be linked
		 * @return TRUE if error
		 * 
		 */
		public function establish(nodes:VirtualNodeCollection):Boolean
		{
			// Needs to connect at least two nodes
			if(nodes == null || nodes.collection.length < 2)
				return true;
			
			// Allocate interfaces needed
			interfaceRefs = new VirtualInterfaceReferenceCollection();
			for each(var connectedNode:VirtualNode in nodes.collection)
			{
				var newInterface:VirtualInterface = connectedNode.allocateExperimentalInterface();
				// Failed to get a valid interface
				if(newInterface == null)
				{
					interfaceRefs = new VirtualInterfaceReferenceCollection();
					return true;
				}
				interfaceRefs.add(newInterface);
			}
			
			clientId = nodes.collection[0].slice.getUniqueId(this, "link");
			
			var firstManager:GeniManager = nodes.collection[0].manager;
			var sameManager:Boolean = true;
			var needsIps:Boolean = false;
			var needsCapacity:Boolean = true;
			var addedInterface:VirtualInterface;
			for each(addedInterface in interfaceRefs.Interfaces.collection)
			{
				addedInterface.Owner.interfaces.add(addedInterface);
				addedInterface.links.add(this);
				if(firstManager != addedInterface.Owner.manager)
					sameManager = false;
				if(addedInterface.Owner.sliverType.name == SliverTypes.JUNIPER_LROUTER)
					needsIps = true;
				if(!addedInterface.Owner.Vm)
					needsCapacity = false;
				addedInterface.Owner.unsubmittedChanges = true;
			}
			
			if(sameManager)
			{
				type.name = LinkType.LAN_V2;
				if(needsIps)
				{
					VirtualInterface.startNextTunnel();
					for each(addedInterface in interfaceRefs.Interfaces.collection)
					{
						if(addedInterface.ip == null || addedInterface.ip.address.length == 0)
						{
							addedInterface.ip = new Ip(VirtualInterface.getNextTunnel());
							addedInterface.ip.netmask = "255.255.255.0";
							addedInterface.ip.type = "ipv4";
						}
					}
				}
			}
			else
			{
				/*if(first.manager.supportsIon && second.manager.supportsIon && Main.useIon)
					linkType = TYPE_ION;
				else if (first.manager.supportsGpeni && second.manager.supportsGpeni && Main.useGpeni)
					linkType = TYPE_GPENI;
				else*/
				setUpTunnels();
			}
			
			setUpProperties();
			if(sameManager && needsCapacity)
			{
				Capacity = 100000;
			}
			unsubmittedChanges = true;
			
			return false;
		}
		
		/**
		 * 
		 * @param node Node wanting to be added to the link
		 * @return TRUE if node can be added to the link
		 * 
		 */
		public function canAddNode(node:VirtualNode):Boolean
		{
			// Must already be established
			if(interfaceRefs.length < 2)
				return false;
			
			// Make sure we can allocate
			if(node.allocateExperimentalInterface() == null)
				return false;
			
			return true;
		}
		
		/**
		 * 
		 * @param node Node to add into link
		 * @return TRUE if not added
		 * 
		 */
		public function addNode(node:VirtualNode):Boolean
		{
			// Must already be established
			if(interfaceRefs.length < 2)
				return true;
			
			// Allocate interface needed
			var newInterface:VirtualInterface = node.allocateExperimentalInterface();
			if(newInterface == null)
				return true;
			
			interfaceRefs.add(newInterface);
			
			newInterface.Owner.interfaces.add(newInterface);
			newInterface.links.add(this);
			
			if(type.name == LinkType.LAN_V2 && node.manager != interfaceRefs.collection[0].referencedInterface.Owner.manager)
				type.name = LinkType.GRETUNNEL_V2;
			
			if(type.name == LinkType.GRETUNNEL_V2)
				setUpTunnels();
			
			setUpProperties();
			unsubmittedChanges = true;
			
			return false;
		}
		
		/**
		 * 
		 * @param node Node to remove
		 * 
		 */
		public function removeNode(node:VirtualNode):void
		{
			var interfacesToCheck:VirtualInterfaceCollection = interfaceRefs.Interfaces;
			for(var i:int = 0; i < interfacesToCheck.length; i++)
			{
				var vi:VirtualInterface = interfacesToCheck.collection[i];
				if(vi.Owner == node)
				{
					removeInterface(vi);
					i--;
				}
			}
			unsubmittedChanges = true;
		}
		
		/**
		 * 
		 * @param iface Virtual interface or reference for interface to remove
		 * 
		 */
		public function removeInterface(iface:*):void
		{
			var interfaceReference:VirtualInterfaceReference;
			if(iface is VirtualInterface)
				interfaceReference = interfaceRefs.getReferenceFor(iface);
			else
				interfaceReference = iface;
			
			properties.removeAnyWithInterface(interfaceReference.referencedInterface);
			
			interfaceReference.referencedInterface.Owner.interfaces.remove(iface);
			interfaceReference.referencedInterface.links.remove(this);
			interfaceReference.referencedInterface.Owner.cleanupPipes();
			
			interfaceRefs.remove(interfaceReference);
			
			unsubmittedChanges = true;
		}
		
		/**
		 * Removes all interface references and removes itself from the slice
		 * 
		 */
		public function removeFromSlice():void
		{
			for each(var gm:GeniManager in this.interfaceRefs.Interfaces.Managers.collection)
			{
				var sliver:Sliver = slice.slivers.getOrCreateByManager(gm, slice);
				if(sliver.Created)
					sliver.UnsubmittedChanges = true;
			}
			removeInterfaceReferences();
			slice.links.remove(this);
		}
		
		/**
		 * Removes all of the interfaces
		 * 
		 */
		public function removeInterfaceReferences():void
		{
			var interfacesToRemove:VirtualInterfaceCollection = interfaceRefs.Interfaces;
			for each(var iface:VirtualInterface in interfacesToRemove.collection)
			{
				removeInterface(iface);
			}
		}
		
		/**
		 * Sets up tunnels for all of the interfaces
		 * 
		 */
		public function setUpTunnels():void
		{
			type.name = LinkType.GRETUNNEL_V2;
			VirtualInterface.startNextTunnel();
			for each(var i:VirtualInterface in interfaceRefs.Interfaces.collection)
			{
				if(i.ip == null || i.ip.address.length == 0)
				{
					i.ip = new Ip(VirtualInterface.getNextTunnel());
					i.ip.netmask = "255.255.255.0";
					i.ip.type = "ipv4";
				}
			}
		}
		
		/**
		 * Ensures properties exist for all interfaces
		 * 
		 */
		public function setUpProperties():void
		{
			var property:Property;
			// Add missing properties
			for each(var sourceInterface:VirtualInterface in interfaceRefs.Interfaces.collection)
			{
				for each(var destInterface:VirtualInterface in interfaceRefs.Interfaces.collection)
				{
					if(sourceInterface == destInterface)
						continue;
					property = properties.getFor(sourceInterface, destInterface);
					if(property == null)
					{
						property = new Property(sourceInterface, destInterface);
						properties.add(property);
					}
				}
			}
			// Remove invalid properties
			for(var i:int = 0; i < properties.length; i++)
			{
				property = properties.collection[i];
				if(interfaceRefs.getReferenceFor(property.source) == null || interfaceRefs.getReferenceFor(property.destination) == null)
				{
					properties.remove(property);
					i--;
				}
			}
		}
		
		public function get SupportsIon():Boolean
		{
			for each(var i:VirtualInterface in interfaceRefs.Interfaces.collection)
			{
				if(!i.Owner.manager.supportsIon)
					return false;
			}
			return true;
		}
		
		public function get SupportsGpeni():Boolean
		{
			for each(var i:VirtualInterface in interfaceRefs.Interfaces.collection)
			{
				if(!i.Owner.manager.supportsGpeni)
					return false;
			}
			return true;
		}
		
		override public function toString():String
		{
			var result:String =
				"[VirtualLink\n\t\tClientID="+clientId
				+",\n\t\t"+StringProperties
				+"]";
			// XXX Services
			result += "\n\t\t[InterfaceReferences]";
			for each(var ifaceref:VirtualInterfaceReference in interfaceRefs.collection)
				result += "\n\t\t\t"+ifaceref.toString();
			result += "\n\t\t[/InterfaceReferences]";
			result += "\n\t\t[Properties]";
			for each(var property:Property in properties.collection)
				result += "\n\t\t\t"+property.toString();
			result += "\n\t\t[/Properties]";
			return result + "\n\t[/VirtualLink]";
		}
	}
}