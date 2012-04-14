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
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.sites.SupportedLinkType;
	import com.flack.geni.resources.sites.SupportedLinkTypeCollection;
	import com.flack.geni.resources.virtual.extensions.LinkFlackInfo;
	import com.flack.shared.utils.StringUtil;

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
		
		// Flack extension
		public var flackInfo:LinkFlackInfo = new LinkFlackInfo();
		
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
		 * @return TRUE if link is point-to-point and one-way
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
		 * @return TRUE if link is point-to-point and two-way
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
		 * @param nodes Nodes wanting to create link for
		 * @return TRUE if link can be made
		 * 
		 */
		public static function canEstablish(nodes:VirtualNodeCollection):Boolean
		{
			// Needs to connect nodes
			if(nodes == null || nodes.length == 0)
				return false;
			
			// Need to have some link type which is available
			if(nodes.Managers.CommonLinkTypes.supportedFor(nodes).length == 0)
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
		 * @param useType Link type to use, fail if not available
		 * @return TRUE if error
		 * 
		 */
		public function establish(nodes:VirtualNodeCollection, useType:String = ""):Boolean
		{
			if(!canEstablish(nodes))
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
			
			// Select the link type
			var supportedTypes:SupportedLinkTypeCollection = nodes.Managers.CommonLinkTypes.supportedFor(nodes);
			var selectedType:SupportedLinkType = null;
			// If explicitly chosen, use the given link type
			if(useType.length > 0)
				selectedType = supportedTypes.getByName(useType);
			else
				selectedType = supportedTypes.preferredType(nodes.length);
			
			// Make sure the link can support the nodes
			if(selectedType == null || selectedType.maxConnections < nodes.length)
			{
				interfaceRefs = new VirtualInterfaceReferenceCollection();
				return true;
			}
			
			for each(var addedInterface:VirtualInterface in interfaceRefs.Interfaces.collection)
			{
				addedInterface.Owner.interfaces.add(addedInterface);
				addedInterface.links.add(this);
				if(addedInterface.Owner.sliverType.sliverTypeSpecific != null)
					addedInterface.Owner.sliverType.sliverTypeSpecific.interfaceAdded(addedInterface);
				addedInterface.Owner.unsubmittedChanges = true;
			}
			
			changeToType(selectedType);
			
			setUpProperties();
			unsubmittedChanges = true;
			
			return false;
		}
		
		public function changeToType(selectedType:SupportedLinkType):void
		{
			
			
			// Establish or change clientId according to type if possible
			if(clientId.length == 0)
				clientId = slice.getUniqueId(this, selectedType.name);
			else if(selectedType.name != type.name && clientId.indexOf(type.name) == 0)
				clientId = clientId.replace(type.name, selectedType.name);
			
			var makeCapacity:Number = selectedType.defaultCapacity;
			switch(selectedType.name)
			{
				case LinkType.LAN_V1:
				case LinkType.LAN_V2:
					type.name = LinkType.LAN_V2;
					for each(var addedInterface:VirtualInterface in interfaceRefs.Interfaces.collection)
					{
						if(addedInterface.Owner.Vm)
						{
							makeCapacity = 100000;
							break;
						}
					}
					break;
				case LinkType.ION:
					type.name = LinkType.ION;
					break;
				case LinkType.GPENI:
					type.name = LinkType.GPENI;
					break;
				case LinkType.GRETUNNEL_V1:
				case LinkType.GRETUNNEL_V2:
					type.name = LinkType.GRETUNNEL_V2;
					break;
				default:
					type.name = selectedType.name;
			}
			
			if(!isNaN(makeCapacity))
				Capacity = makeCapacity;
			
			if(selectedType.requiresIpAddresses)
				setupIpAddresses();
		}
		
		public function setupIpAddresses():void
		{
			interfaceRefs.Interfaces.setupIpAddresses(false);
		}
		
		/**
		 * 
		 * @param node Node wanting to be added to the link
		 * @return TRUE if node can be added to the link
		 * 
		 */
		public function canAddNode(node:VirtualNode):Boolean
		{
			var supportedLinkType:SupportedLinkType = node.manager.supportedLinkTypes.getByName(type.name);
			
			// Node must support same link type
			if(supportedLinkType == null)
				return false;
			
			// Link type must support adding another node
			if(interfaceRefs.length >= supportedLinkType.maxConnections)
				return false;
			
			// If link only supports same manager, cannot add from another manager
			if(interfaceRefs.length > 0
				&& !supportedLinkType.supportsManyManagers
				&& interfaceRefs.collection[0].referencedInterface.Owner.manager != node.manager)
			{
				return false;
			}
			
			// If link only supports different managers, cannot add from existing manager
			if(interfaceRefs.length > 0
				&& !supportedLinkType.supportsSameManager
				&& interfaceRefs.Interfaces.Managers.contains(node.manager))
			{
				return false;
			}
			
			// Don't add new interfaces to the same node
			if(interfaceRefs.Interfaces.Nodes.contains(node))
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
			if(!canAddNode(node))
				return true;
			
			// Allocate interface needed
			var newInterface:VirtualInterface = node.allocateExperimentalInterface();
			if(newInterface == null)
				return true;
			
			interfaceRefs.add(newInterface);
			
			newInterface.Owner.interfaces.add(newInterface);
			newInterface.links.add(this);
			
			// XXX change?
			
			if(node.sliverType.sliverTypeSpecific != null)
				node.sliverType.sliverTypeSpecific.interfaceAdded(newInterface);
			
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
			for each(var vi:VirtualInterface in interfacesToCheck.collection)
			{
				if(vi.Owner == node)
					removeInterface(vi);
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
			
			if(interfaceReference != null)
			{
				properties.removeAnyWithInterface(interfaceReference.referencedInterface);
				
				interfaceReference.referencedInterface.Owner.interfaces.remove(iface);
				interfaceReference.referencedInterface.links.remove(this);
				if(interfaceReference.referencedInterface.Owner.sliverType.sliverTypeSpecific != null)
					interfaceReference.referencedInterface.Owner.sliverType.sliverTypeSpecific.interfaceRemoved(iface);
				
				interfaceRefs.remove(interfaceReference);
			}
			
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
		
		public function supportsType(name:String):Boolean
		{
			for each(var i:VirtualInterface in interfaceRefs.Interfaces.collection)
			{
				if(i.Owner.manager.supportedLinkTypes.getByName(name) == null)
					return false;
			}
			return true;
		}
		
		public function UnboundCloneFor(newSlice:Slice):VirtualLink
		{
			var newClone:VirtualLink = new VirtualLink(newSlice);
			if(newSlice.isIdUnique(newClone, clientId))
				newClone.clientId = clientId;
			else
				newClone.clientId = newSlice.getUniqueId(newClone, StringUtil.makeSureEndsWith(clientId,"-"));
			newClone.type = type;
			newClone.flackInfo.unboundVlantag = flackInfo.unboundVlantag;
			return newClone;
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