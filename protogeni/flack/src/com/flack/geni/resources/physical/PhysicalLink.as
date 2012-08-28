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

package com.flack.geni.resources.physical
{
	import com.flack.geni.resources.Property;
	import com.flack.geni.resources.PropertyCollection;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.shared.resources.physical.PhysicalComponent;

	/**
	 * Link between two resources as described by a manager advertisement
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalLink extends PhysicalComponent
	{
		[Bindable]
		public var linkTypes:Vector.<String> = new Vector.<String>();
		public var interfaces:PhysicalInterfaceCollection = new PhysicalInterfaceCollection();
		public var properties:PropertyCollection = new PropertyCollection();
		
		private var _capacity:Number = NaN;
		/**
		 * 
		 * @param value Capacity for all paths in the link
		 * 
		 */
		public function set Capacity(value:Number):void
		{
			for each(var sourceInterface:PhysicalInterface in interfaces.collection)
			{
				for each(var destInterface:PhysicalInterface in interfaces.collection)
				{
					if(sourceInterface == destInterface)
						continue;
					var property:Property = properties.getFor(sourceInterface, destInterface);
					if(property == null)
					{
						property = new Property(sourceInterface, destInterface);
						properties.add(property);
					}
					property.capacity = value;
				}
			}
			_capacity = value;
		}
		/**
		 * 
		 * @return Max capacity of the link
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
		
		private var _packetLoss:Number = NaN;
		/**
		 * 
		 * @param value Packet loss for all paths in the link
		 * 
		 */
		public function set PacketLoss(value:Number):void
		{
			for each(var sourceInterface:PhysicalInterface in interfaces.collection)
			{
				for each(var destInterface:PhysicalInterface in interfaces.collection)
				{
					if(sourceInterface == destInterface)
						continue;
					var property:Property = properties.getFor(sourceInterface, destInterface);
					if(property == null)
					{
						property = new Property(sourceInterface, destInterface);
						properties.add(property);
					}
					property.packetLoss = value;
				}
			}
			_packetLoss = value;
		}
		/**
		 * 
		 * @return Maximum packet loss for all paths in the link
		 * 
		 */
		public function get PacketLoss():Number
		{
			var maxPacketLoss:Number = 0;
			for each(var property:Property in properties.collection)
			{
				if(property.capacity && property.packetLoss > maxPacketLoss)
					maxPacketLoss = property.packetLoss;
			}
			return maxPacketLoss;
		}
		
		private var _latency:Number = NaN;
		/**
		 * 
		 * @param value Latency for all paths in the link
		 * 
		 */
		public function set Latency(value:Number):void
		{
			for each(var sourceInterface:PhysicalInterface in interfaces.collection)
			{
				for each(var destInterface:PhysicalInterface in interfaces.collection)
				{
					if(sourceInterface == destInterface)
						continue;
					var property:Property = properties.getFor(sourceInterface, destInterface);
					if(property == null)
					{
						property = new Property(sourceInterface, destInterface);
						properties.add(property);
					}
					property.latency = value;
				}
			}
			_latency = value;
		}
		/**
		 * 
		 * @return Maximum latency of all the paths in the link
		 * 
		 */
		public function get Latency():Number
		{
			var maxLatency:Number = 0;
			for each(var property:Property in properties.collection)
			{
				if(property.capacity && property.latency > maxLatency)
					maxLatency = property.latency;
			}
			return maxLatency;
		}
		
		/**
		 * 
		 * @param newManager Manager
		 * @param newId IDN-URN
		 * @param newName Short name
		 * @param newAdvertisement Advertisement
		 * 
		 */
		public function PhysicalLink(newManager:GeniManager = null,
									 newId:String = "",
									 newName:String = "",
									 newAdvertisement:String = "")
		{
			super(newManager, newId, newName, newAdvertisement);
		}
		
		/**
		 * 
		 * @return TRUE if the link only uses nodes from the same location
		 * 
		 */
		public function get SameSite():Boolean
		{
			return interfaces.Locations.length == 1;
		}
		
		override public function toString():String
		{
			var result:String =
				"\t\t[PhysicalLink\n"
				+"\t\t\tName="+name
				+",\n\t\t\tID="+id.full
				+",\n\t\tManagerID="+manager.id.full
				+",\n\t\t]";
			if(interfaces.length > 0)
			{
				result += "\n\t\t[InterfaceRefs]";
				for each(var iface:PhysicalInterface in interfaces.collection)
					result += "\n\t\t\t"+iface.toString();
				result += "\n\t\t[/InterfaceRefs]";
			}
			if(linkTypes.length > 0)
			{
				result += "\n\t\t\t[LinkTypes]";
				for each(var htype:String in linkTypes)
					result += "\n\t\t\t\t[LinkType Name="+htype+"]";
				result += "\n\t\t\t[/LinkTypes]";
			}
			if(properties.length > 0)
			{
				result += "\n\t\t[Properties]";
				for each(var property:Property in properties.collection)
					result += "\n\t\t\t"+property.toString();
				result += "\n\t\t[/Properties]";
			}
			
			return result + "\n\t\t[/PhysicalLink]\n";
		}
	}
}