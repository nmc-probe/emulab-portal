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

package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.physical.PhysicalNode;

	/**
	 * Collection of slices
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
		
		public function add(slice:VirtualNode):void
		{
			collection.push(slice);
		}
		
		public function remove(slice:VirtualNode):void
		{
			var idx:int = collection.indexOf(slice);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(slice:VirtualNode):Boolean
		{
			return collection.indexOf(slice) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get UnsubmittedChanges():Boolean
		{
			for each(var node:VirtualNode in collection)
			{
				if(node.unsubmittedChanges)
					return true;
			}
			return false;
		}
		
		public function get Experiments():ExperimentCollection
		{
			var experiments:ExperimentCollection = new ExperimentCollection();
			for each(var node:VirtualNode in collection)
			{
				if(!experiments.contains(node.experiment))
					experiments.add(node.experiment);
			}
			return experiments;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Slice with the given ID
		 * 
		 */
		public function getByName(name:String):VirtualNode
		{
			for each(var existing:VirtualNode in collection)
			{
				if(existing.name == name)
					return existing;
			}
			return null;
		}
		
		public function getByPhysicalName(name:String):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var existing:VirtualNode in collection)
			{
				if(existing.physicalName == name)
					nodes.add(existing);
			}
			return nodes;
		}
		
		public function getBoundTo(node:PhysicalNode):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var existing:VirtualNode in collection)
			{
				if(existing.Physical == node)
					nodes.add(existing);
			}
			return nodes;
		}
		
		public function searchByName(name:String):VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each (var v:VirtualNode in collection)
			{
				if(v.name.indexOf(name) != -1)
					nodes.add(v);
			}
			return nodes;
		}
		
		public function isIdUnique(node:*, name:String):Boolean
		{
			var found:Boolean = false;
			for each(var testNode:VirtualNode in collection)
			{
				if(node == testNode)
					continue;
				if(testNode.name == name)
					return false;
				//if(!testNode.interfaces.isIdUnique(node, name))
				//	return false;
			}
			return true;
		}
	}
}