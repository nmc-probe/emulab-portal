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

package com.flack.emulab.resources.physical
{
	/**
	 * Collection of hardware types
	 * @author mstrum
	 * 
	 */
	public class PhysicalNodeCollection
	{
		public var collection:Vector.<PhysicalNode>;
		public function PhysicalNodeCollection()
		{
			collection = new Vector.<PhysicalNode>();
		}
		
		public function add(ht:PhysicalNode):void
		{
			collection.push(ht);
		}
		
		public function remove(ht:PhysicalNode):void
		{
			var idx:int = collection.indexOf(ht);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(ht:PhysicalNode):Boolean
		{
			return collection.indexOf(ht) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get Clone():PhysicalNodeCollection
		{
			var clone:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each(var node:PhysicalNode in collection)
				clone.add(node);
			return clone;
		}
		
		public function getByName(name:String):PhysicalNode
		{
			for each(var node:PhysicalNode in collection)
			{
				if(node.name == name)
					return node;
			}
			return null;
		}
		
		public function get Types():Vector.<String>
		{
			var types:Vector.<String> = new Vector.<String>();
			for each(var node:PhysicalNode in collection)
			{
				if(node.hardwareType.length>0 && types.indexOf(node.hardwareType) == -1)
					types.push(node.hardwareType);
			}
			return types;
		}
		
		public function get AuxTypes():Vector.<String>
		{
			var types:Vector.<String> = new Vector.<String>();
			for each(var node:PhysicalNode in collection)
			{
				for each(var auxType:String in node.auxTypes)
				{
					if(types.indexOf(auxType) == -1)
						types.push(auxType);
				}
			}
			return types;
		}
		
		public function searchByName(name:String):PhysicalNodeCollection
		{
			var nodes:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each (var n:PhysicalNode in collection)
			{
				if(n.name.indexOf(name) != -1)
					nodes.add(n);
			}
			return nodes;
		}
		
		public function getByType(type:String):PhysicalNodeCollection
		{
			var group:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each (var n:PhysicalNode in collection)
			{
				if(n.hardwareType == type)
					group.add(n);
			}
			return group;
		}
		
		public function getByAuxType(type:String):PhysicalNodeCollection
		{
			var group:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each (var n:PhysicalNode in collection)
			{
				for each(var auxType:String in n.auxTypes)
				{
					if(auxType == type)
					{
						group.add(n);
						break;
					}
				}
				
			}
			return group;
		}
		
		public function getByAvailability(available:Boolean):PhysicalNodeCollection
		{
			var group:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each (var n:PhysicalNode in collection)
			{
				if(n.available == available)
					group.add(n);
			}
			return group;
		}
		
		public function get Available():PhysicalNodeCollection
		{
			return getByAvailability(true);
		}
	}
}