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
	import com.flack.geni.resources.physical.PhysicalInterface;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;

	/**
	 * Collection of interfaces from a node in a sliver/slice
	 * 
	 * @author mstrum
	 * 
	 */
	public final class VirtualInterfaceCollection
	{
		[Bindable]
		public var collection:Vector.<VirtualInterface>;
		public function VirtualInterfaceCollection()
		{
			collection = new Vector.<VirtualInterface>();
		}
		
		public function add(virtualInterface:VirtualInterface):void
		{
			collection.push(virtualInterface);
		}
		
		public function remove(virtualInterface:VirtualInterface):void
		{
			var idx:int = collection.indexOf(virtualInterface);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(virtualInterface:VirtualInterface):Boolean
		{
			return collection.indexOf(virtualInterface) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param id Sliver ID
		 * @return Interface with the given sliver ID
		 * 
		 */
		public function getBySliverId(id:String):VirtualInterface
		{
			for each(var testInterface:VirtualInterface in collection)
			{
				if(testInterface.id.full == id)
					return testInterface;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id Client ID
		 * @return Interface with the given client ID
		 * 
		 */
		public function getByClientId(id:String):VirtualInterface
		{
			for each(var testInterface:VirtualInterface in collection)
			{
				if(testInterface.clientId == id)
					return testInterface;
			}
			return null;
		}
		
		/**
		 * 
		 * @param physicalInterface Physical interface
		 * @return Virtual interface bound to the given physical interface
		 * 
		 */
		public function getBoundTo(physicalInterface:PhysicalInterface):VirtualInterface
		{
			for each(var testInterface:VirtualInterface in collection)
			{
				if(testInterface.Physical == physicalInterface)
					return testInterface;
			}
			return null;
		}
		
		public function getByHost(vnode:VirtualNode):VirtualInterface
		{
			for each(var testInterface:VirtualInterface in collection)
			{
				if(testInterface._owner == vnode)
					return testInterface;
			}
			return null;
		}
		
		public function getByManager(manager:GeniManager):VirtualInterfaceCollection
		{
			var ifaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
			for each(var iface:VirtualInterface in collection)
			{
				if(iface._owner.manager == manager)
					ifaces.add(iface);
			}
			return ifaces;
		}
		
		public function getByHostOtherThan(vnode:VirtualNode):VirtualInterfaceCollection
		{
			var ifaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
			for each(var testInterface:VirtualInterface in collection)
			{
				if(testInterface._owner != vnode)
					ifaces.add(testInterface);
			}
			return ifaces;
		}
		
		/**
		 * 
		 * @param testing Object wishing to use the client ID
		 * @param id Desired client ID
		 * @return TRUE if object can use the client ID
		 * 
		 */
		public function isIdUnique(testing:*, id:String):Boolean
		{
			for each(var testInterface:VirtualInterface in collection)
			{
				if(testInterface == testing)
					continue;
				if(testInterface.clientId == id)
					return false;
			}
			return true;
		}
		
		/**
		 * 
		 * @return All links
		 * 
		 */
		public function get Links():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var testInterface:VirtualInterface in collection)
			{
				for each(var testLink:VirtualLink in testInterface.links.collection)
				{
					if(!links.contains(testLink))
						links.add(testLink);
				}
			}
			return links;
		}
		
		/**
		 * 
		 * @return All nodes
		 * 
		 */
		public function get Nodes():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testInterface:VirtualInterface in collection)
			{
				if(!nodes.contains(testInterface.Owner))
					nodes.add(testInterface.Owner);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @return Managers
		 * 
		 */
		public function get Managers():GeniManagerCollection
		{
			var managers:GeniManagerCollection = new GeniManagerCollection();
			for each(var testInterface:VirtualInterface in collection)
			{
				if(!managers.contains(testInterface.Owner.manager))
					managers.add(testInterface.Owner.manager);
			}
			return managers;
		}
		
		public function setupIpAddresses(forceNew:Boolean = false):void
		{
			VirtualInterface.startNextTunnel();
			for each(var addedInterface:VirtualInterface in collection)
			{
				if(forceNew || addedInterface.ip == null || addedInterface.ip.address.length == 0)
				{
					addedInterface.ip = new Ip(VirtualInterface.getNextTunnel());
					addedInterface.ip.netmask = "255.255.255.0";
					addedInterface.ip.type = "ipv4";
				}
			}
		}
	}
}