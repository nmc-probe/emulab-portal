/* 
 * Copyright (c) 2008-2012 University of Utah and the Flux Group.
 * 
 * {{{GENIPUBLIC-LICENSE
 * 
 * GENI Public License
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and/or hardware specification (the "Work") to
 * deal in the Work without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Work, and to permit persons to whom the Work
 * is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Work.
 * 
 * THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
 * IN THE WORK.
 * 
 * }}}
 */

package com.flack.geni.resources.virtual
{
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.resources.physical.PhysicalInterface;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.physical.PhysicalNodeCollection;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;

	/**
	 * Collection of virtual nodes
	 * 
	 * @author mstrum
	 * 
	 */
	public final class VirtualNodeCollection
	{
		public var collection:Vector.<VirtualNode>;
		public function VirtualNodeCollection()
		{
			collection = new Vector.<VirtualNode>();
		}
		
		public function add(n:VirtualNode):void
		{
			collection.push(n);
		}
		
		public function remove(n:VirtualNode):void
		{
			var idx:int = collection.indexOf(n);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(n:VirtualNode):Boolean
		{
			return collection.indexOf(n) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @return Instance with the same collection
		 * 
		 */
		public function get Clone():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var node:VirtualNode in collection)
				nodes.add(node);
			return nodes;
		}
		
		/**
		 * 
		 * @return Nodes which have been allocated
		 * 
		 */
		public function get Created():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var node:VirtualNode in collection)
			{
				if(node.Created)
					nodes.add(node);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @return Nodes which are bound
		 * 
		 */
		public function get Bound():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var node:VirtualNode in collection)
			{
				if(node.Bound)
					nodes.add(node);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @return Slices for the nodes
		 * 
		 */
		public function get Slices():SliceCollection
		{
			var slices:SliceCollection = new SliceCollection();
			for each(var node:VirtualNode in collection)
			{
				if(!slices.contains(node.slice))
					slices.add(node.slice);
			}
			return slices;
		}
		
		public function get UniqueSliverTypeInterfaces():Vector.<SliverTypeInterface>
		{
			var ifaces:Vector.<SliverTypeInterface> = new Vector.<SliverTypeInterface>();
			for each(var node:VirtualNode in collection)
			{
				if(node.sliverType.sliverTypeSpecific != null)
				{
					var add:Boolean = true;
					for each(var existing:SliverTypeInterface in ifaces)
					{
						if(existing.Name == node.sliverType.sliverTypeSpecific.Name)
						{
							add = false;
							break;
						}
					}
					if(add)
						ifaces.push(node.sliverType.sliverTypeSpecific);
				}
			}
			return ifaces;
		}
		
		/**
		 * 
		 * @return TRUE if changes have been made but not submitted
		 * 
		 */
		public function get UnsubmittedChanges():Boolean
		{
			for each(var node:VirtualNode in collection)
			{
				if(node.unsubmittedChanges)
					return true;
			}
			return false;
		}
		
		/**
		 * 
		 * @param nodes Nodes to see if same
		 * @return TRUE if this collection same as given
		 * 
		 */
		public function sameAs(nodes:VirtualNodeCollection):Boolean
		{
			if(length != nodes.length)
				return false;
			for each(var node:VirtualNode in collection)
			{
				if(!nodes.contains(node))
					return false;
			}
			return true;
		}
		
		/**
		 * 
		 * @param node Node asking about
		 * @param id New ID for given node
		 * @return TRUE if ID will be unique
		 * 
		 */
		public function isIdUnique(node:*, id:String):Boolean
		{
			var found:Boolean = false;
			for each(var testNode:VirtualNode in collection)
			{
				if(node == testNode)
					continue;
				if(testNode.clientId == id)
					return false;
				if(!testNode.interfaces.isIdUnique(node, id))
					return false;
			}
			return true;
		}
		
		/**
		 * 
		 * @param id Client ID
		 * @return Node with the given client ID
		 * 
		 */
		public function getByClientId(id:String):VirtualNode
		{
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.clientId == id)
					return testNode;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id Sliver ID
		 * @return Node with the given sliver ID
		 * 
		 */
		public function getBySliverId(id:String):VirtualNode
		{
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.id.full == id)
					return testNode;
			}
			return null;
		}
		
		/**
		 * 
		 * @param type Sliver type
		 * @return Nodes with the given sliver type selected
		 * 
		 */
		public function getBySliverType(type:String):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.sliverType.name == type)
					nodes.add(testNode);
			}
			
			return nodes;
		}
		
		/**
		 * 
		 * @param slice Slice we want nodes for
		 * @return All nodes from the given slice
		 * 
		 */
		public function getBySlice(slice:Slice):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.slice == slice)
					nodes.add(testNode);
			}
			
			return nodes;
		}
		
		/**
		 * 
		 * @param physicalNode Phsyical node
		 * @return Virtual nodes bound to the given physical node
		 * 
		 */
		public function getBoundTo(physicalNode:PhysicalNode):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.Physical == physicalNode)
					nodes.add(testNode);
			}
			
			return nodes;
		}
		
		/**
		 * 
		 * @param physicalNodes Physical nodes
		 * @return Virtual nodes bounded to the given physical nodes
		 * 
		 */
		public function getByPhysicalNodes(physicalNodes:PhysicalNodeCollection):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.Bound && physicalNodes.contains(testNode.Physical))
					nodes.add(testNode);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @param exclusive Should nodes be exclusive?
		 * @return Nodes with the given exclusivity
		 * 
		 */
		public function getByExclusivity(exclusive:Boolean):VirtualNodeCollection
		{
			var group:VirtualNodeCollection = new VirtualNodeCollection();
			for each (var v:VirtualNode in collection)
			{
				if(v.exclusive == exclusive)
					group.add(v);
			}
			return group;
		}
		
		/**
		 * 
		 * @return All exclusive nodes
		 * 
		 */
		public function get Exclusive():VirtualNodeCollection
		{
			return getByExclusivity(true);
		}
		
		/**
		 * 
		 * @return All shared nodes
		 * 
		 */
		public function get Shared():VirtualNodeCollection
		{
			return getByExclusivity(false);
		}
		
		/**
		 * 
		 * @param manager Manager
		 * @return Nodes from the given manager
		 * 
		 */
		public function getByManager(manager:GeniManager):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.manager == manager)
					nodes.add(testNode);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @param managers Managers
		 * @return Nodes from the given managers
		 * 
		 */
		public function getByManagers(managers:GeniManagerCollection):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(managers.contains(testNode.manager))
					nodes.add(testNode);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @param manager Manager
		 * @return Nodes from managers excluding the given manager
		 * 
		 */
		public function getByManagersOtherThan(manager:GeniManager):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var testNode:VirtualNode in collection)
			{
				if(testNode.manager != manager)
					nodes.add(testNode);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @param id Interface IDN-URN
		 * @return Virtual interface with the given client ID
		 * 
		 */
		public function getInterfaceByClientId(id:String):VirtualInterface
		{
			for each(var testNode:VirtualNode in collection)
			{
				var testInterface:VirtualInterface = testNode.interfaces.getByClientId(id);
				if(testInterface != null)
					return testInterface;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id Interface sliver ID
		 * @return Interface with the given sliver ID
		 * 
		 */
		public function getInterfaceBySliverId(id:String):VirtualInterface
		{
			for each(var testNode:VirtualNode in collection)
			{
				var testInterface:VirtualInterface = testNode.interfaces.getBySliverId(id);
				if(testInterface != null)
					return testInterface;
			}
			return null;
		}
		
		/**
		 * 
		 * @param physicalInterface Physical interface
		 * @return Virtual interface bounded to the given physical interface
		 * 
		 */
		public function getInterfaceBoundTo(physicalInterface:PhysicalInterface):VirtualInterface
		{
			for each(var testNode:VirtualNode in collection)
			{
				var candidate:VirtualInterface = testNode.interfaces.getBoundTo(physicalInterface);
				if(candidate != null)
					return candidate;
			}
			
			return null;
		}
		
		/**
		 * 
		 * @param clientId Partial client ID
		 * @return Nodes with a client id matching part of the given string
		 * 
		 */
		public function searchByClientId(clientId:String):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each (var v:VirtualNode in collection)
			{
				if(v.clientId.indexOf(clientId) != -1)
					nodes.add(v);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @return Physical nodes bounded by the virtual nodes
		 * 
		 */
		public function get PhysicalNodes():PhysicalNodeCollection
		{
			var nodes:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each(var n:VirtualNode in collection)
			{
				var pnode:PhysicalNode = n.Physical;
				if(pnode != null && !nodes.contains(pnode))
					nodes.add(pnode);
			}
			return nodes;
		}
		
		/**
		 * 
		 * @return Managers of the nodes
		 * 
		 */
		public function get Managers():GeniManagerCollection
		{
			var managers:GeniManagerCollection = new GeniManagerCollection();
			for each(var n:VirtualNode in collection)
			{
				if(n.manager != null && !managers.contains(n.manager))
					managers.add(n.manager);
			}
			return managers;
		}
		
		/**
		 * 
		 * @return Logins
		 * 
		 */
		public function get Logins():String
		{
			var logins:String = "";
			for each(var n:VirtualNode in collection)
			{
				if(n.services.loginServices.length > 0)
				{
					logins +=
						(logins.length > 0 ? "\n" : "")
						+ n.clientId
						+ "\t"
						+ n.services.loginServices[0].FullLogin
				}
			}
			return logins;
		}
		
		public function get MiddleX():Number
		{
			var middleX:Number = 0;
			for each(var n:VirtualNode in collection)
				middleX += n.flackInfo.x;
			return middleX/length;
		}
		
		public function get MiddleY():Number
		{
			var middleY:Number = 0;
			for each(var n:VirtualNode in collection)
				middleY += n.flackInfo.y;
			return middleY/length;
		}
	}
}