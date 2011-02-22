/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2009 University of Utah and the Flux Group.
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
	import mx.collections.ArrayCollection;
	
	// Link as part of a sliver/slice connecting virtual nodes
	public class VirtualLink
	{
		// Status values
		public static var TUNNEL : String = "tunnel";
		
		public function VirtualLink(owner:Sliver)
		{
			slivers = new Array(owner);
		}
		
		[Bindable]
		public var id:String;
		
		public var type:String;
		
		[Bindable]
		public var interfaces:ArrayCollection = new ArrayCollection();
		
		[Bindable]
		public var bandwidth:Number;
		
		public var firstTunnelIp:int = 0;
		public var secondTunnelIp:int = 0;
		public var _isTunnel:Boolean = false;
		
		public var slivers:Array;

		public var rspec:XML;
		
		public var firstNode:VirtualNode;
		public var secondNode:VirtualNode;
		
		public static var tunnelNext:int = 1;
		
		public var urn:String;
		
		public static function getNextTunnel():String
		{
			var first : int = ((tunnelNext >> 8) & 0xff);
			var second : int = (tunnelNext & 0xff);
			tunnelNext++;
			return "192.168." + String(first) + "." + String(second);
		}
		
		public function establish(first:VirtualNode, second:VirtualNode):Boolean
		{
			var firstInterface:VirtualInterface;
			var secondInterface:VirtualInterface;
			if(first.manager != second.manager)
			{
				firstInterface = first.interfaces.GetByID("control");
				secondInterface = second.interfaces.GetByID("control");
				// THIS WILL PROBABLY BREAK VERSION 1!!!!
				/*
				firstInterface = first.allocateInterface();
				secondInterface = second.allocateInterface();
				if(firstInterface == null || secondInterface == null)
					return false;
				first.interfaces.Add(firstInterface);
				second.interfaces.Add(secondInterface);
				*/
				// END OF THE PART WHICH WILL PROBABLY BREAK VERSION 1!!!!
				
				_isTunnel = true;
				if(firstInterface.ip.length == 0)
					firstInterface.ip = getNextTunnel();
				if(secondInterface.ip.length == 0)
					secondInterface.ip = getNextTunnel();
				
				// Make sure nodes are in both
				if(!(second.slivers[0] as Sliver).nodes.contains(first))
					(second.slivers[0] as Sliver).nodes.addItem(first);
				if(!(first.slivers[0] as Sliver).nodes.contains(second))
					(first.slivers[0] as Sliver).nodes.addItem(second);
				
				// Add relative slivers
				if(slivers[0].manager != first.slivers[0].manager)
					slivers.push(first.slivers[0]);
				else if(slivers[0].manager != second.slivers[0].manager)
					slivers.push(second.slivers[0]);
			} else {
				firstInterface = first.allocateInterface();
				secondInterface = second.allocateInterface();
				if(firstInterface == null || secondInterface == null)
					return false;
				first.interfaces.Add(firstInterface);
				second.interfaces.Add(secondInterface);
			}
			
			// Bandwidth
			bandwidth = Math.floor(Math.min(firstInterface.bandwidth, secondInterface.bandwidth));
			if (first.id.slice(0, 2) == "pg" || second.id.slice(0, 2) == "pg")
				bandwidth = 1000000;
			
			this.interfaces.addItem(firstInterface);
			this.interfaces.addItem(secondInterface);
			firstNode = first;
			secondNode = second;
			first.links.addItem(this);
			second.links.addItem(this);
			firstInterface.virtualLinks.addItem(this);
			secondInterface.virtualLinks.addItem(this);
			id = slivers[0].slice.getUniqueVirtualLinkId(this);
			for each(var s:Sliver in slivers)
				s.links.addItem(this);
			if(first.manager == second.manager)
			{
				firstInterface.id = slivers[0].slice.getUniqueVirtualInterfaceId();
				secondInterface.id = slivers[0].slice.getUniqueVirtualInterfaceId();
			}
			return true;
		}
		
		public function remove():void
		{
			for each(var vi:VirtualInterface in this.interfaces)
			{
				if(vi.id != "control")
					vi.virtualNode.interfaces.collection.removeItemAt(vi.virtualNode.interfaces.collection.getItemIndex(vi));
			}
			interfaces.removeAll();
			// Remove nodes
			firstNode.links.removeItemAt(firstNode.links.getItemIndex(this));
			for(var i:int = 1; i < firstNode.slivers.length; i++)
			{
				if((firstNode.slivers.getItemAt(i) as Sliver).links.getForNode(firstNode).length == 0)
					(firstNode.slivers.getItemAt(i) as Sliver).nodes.remove(firstNode);
			}
			secondNode.links.removeItemAt(secondNode.links.getItemIndex(this));
			for(i = 1; i < secondNode.slivers.length; i++)
			{
				if((secondNode.slivers.getItemAt(i) as Sliver).links.getForNode(secondNode).length == 0)
					(secondNode.slivers.getItemAt(i) as Sliver).nodes.remove(secondNode);
			}
			for each(var s:Sliver in slivers)
			{
				s.links.removeItemAt(s.links.getItemIndex(this));
			}
		}
		
		public function isTunnel():Boolean
		{
			if(interfaces.length > 0)
			{
				var basicManager:GeniManager = (interfaces[0] as VirtualInterface).virtualNode.manager;
				for each(var i:VirtualInterface in interfaces)
				{
					if(i.virtualNode.manager != basicManager)
						return true;
				}
			}
			return _isTunnel;
		}
		
		public function hasTunnelTo(target:GeniManager) : Boolean
		{
			return isTunnel() && (this.firstNode.manager == target
				|| secondNode.manager == target);
		}
		
		public function isConnectedTo(target:GeniManager) : Boolean
		{
			if(hasTunnelTo(target))
				return true;
			for each(var i:VirtualInterface in interfaces)
			{
				if(i.virtualNode.manager == target)
					return true;
			}
			return false;
		}
		
		public function hasVirtualNode(node:VirtualNode):Boolean
		{
			for each(var i:VirtualInterface in interfaces)
			{
				if(i.virtualNode == node)
					return true;
			}

			return (firstNode == node || secondNode == node);
		}
		
		public function hasPhysicalNode(node:PhysicalNode):Boolean
		{
			for each(var i:VirtualInterface in interfaces)
			{
				if(!i.virtualNode.isVirtual && i.virtualNode.physicalNode == node)
					return true;
			}
			return false;
		}
	}
}