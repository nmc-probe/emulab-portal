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
	public final class VirtualNodeCollection
	{
		public var collection:Vector.<VirtualNode>;
		public function VirtualNodeCollection()
		{
			this.collection = new Vector.<VirtualNode>();
			/*if(source != null) {
			for each(var node:VirtualNode in source)
			collection.push(node);
			}*/
		}
		
		public function add(n:VirtualNode):void {
			this.collection.push(n);
		}
		
		public function remove(n:VirtualNode):void
		{
			var idx:int = this.collection.indexOf(n);
			if(idx > -1)
				this.collection.splice(idx, 1);
		}
		
		public function contains(n:VirtualNode):Boolean
		{
			return this.collection.indexOf(n) > -1;
		}
		
		public function get length():int{
			return this.collection.length;
		}
		
		public function isIdUnique(node:*, id:String):Boolean {
			var found:Boolean = false;
			for each(var testNode:VirtualNode in this.collection)
			{
				if(node == testNode)
					continue;
				if(testNode.clientId == id)
					return false;
			}
			return true;
		}
		
		public function getByClientId(id:String):VirtualNode
		{
			for each(var node:VirtualNode in this.collection)
			{
				if(node.clientId == id)
					return node;
			}
			return null;
		}
		
		public function getByInterfaceId(id:String):VirtualInterface
		{
			for each(var node:VirtualNode in this.collection)
			{
				var vi:VirtualInterface = node.interfaces.GetByID(id);
				if(vi != null)
					return vi;
			}
			return null;
		}
		
		public function getBySliverId(urn:String):VirtualNode
		{
			for each(var node:VirtualNode in this.collection)
			{
				if(node.sliverId == urn)
					return node;
			}
			return null;
		}
		
		public function getByComponentId(urn:String):VirtualNode
		{
			for each(var node:VirtualNode in this.collection)
			{
				if(node.physicalNode != null && node.physicalNode.id == urn)
					return node;
			}
			return null;
		}
		
		public function getByPhysicalNode(node:PhysicalNode):VirtualNode
		{
			for each(var vn:VirtualNode in this.collection)
			{
				if(vn.physicalNode == node)
					return vn;
			}
			
			return null;
		}
		
		public function getByManager(manager:GeniManager):VirtualNodeCollection
		{
			var newCollection:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var node:VirtualNode in this.collection)
			{
				if(node.manager == manager)
					newCollection.add(node);
			}
			return newCollection;
		}
		
		public function getByManagersOtherThan(manager:GeniManager):VirtualNodeCollection
		{
			var newCollection:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var node:VirtualNode in this.collection)
			{
				if(node.manager != manager)
					newCollection.add(node);
			}
			return newCollection;
		}
	}
}