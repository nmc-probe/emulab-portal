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

package com.flack.geni.display.slicer.graphview
{
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;
	
	import mx.collections.ArrayCollection;
	
	public class CanvasNodeCollection
	{
		public var collection:Vector.<CanvasNode>;
		public function CanvasNodeCollection()
		{
			collection = new Vector.<CanvasNode>();
		}
		
		public function add(node:CanvasNode):void
		{
			collection.push(node);
		}
		
		public function remove(node:CanvasNode):int
		{
			var idx:int = collection.indexOf(node);
			if(idx > -1)
				collection.splice(idx, 1);
			return idx;
		}
		
		public function contains(node:CanvasNode):Boolean
		{
			return collection.indexOf(node) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get VirtualNodes():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each (var cn:CanvasNode in collection)
				nodes.add(cn.Node);
			return nodes;
		}
		
		public function getForVirtualNodes(nodes:VirtualNodeCollection):CanvasNodeCollection
		{
			var results:CanvasNodeCollection = new CanvasNodeCollection();
			for each (var cn:CanvasNode in collection)
			{
				if(nodes.contains(cn.Node))
					results.add(cn);
			}
			return results;
		}
		
		public function getForVirtualNode(node:VirtualNode):CanvasNode
		{
			for each (var cn:CanvasNode in collection)
			{
				if(cn.Node == node)
					return cn;
			}
			return null;
		}
		
		public function seperateNodesByComponentManager():Array
		{
			var completedCms:ArrayCollection = new ArrayCollection();
			var completed:Array = new Array();
			for each(var cn:CanvasNode in collection)
			{
				if(!completedCms.contains(cn.Node.manager))
				{
					var cmNodes:CanvasNodeCollection = new CanvasNodeCollection();
					for each(var sncm:CanvasNode in collection)
					{
						if(sncm.Node.manager == cn.Node.manager)
							cmNodes.add(sncm);
					}
					if(cmNodes.length > 0)
						completed.push(cmNodes);
				}
			}
			return completed;
		}
	}
}