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
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.geni.resources.virtual.VirtualLinkCollection;

	public class CanvasLinkCollection
	{
		public var collection:Vector.<CanvasLink>;
		public function CanvasLinkCollection()
		{
			collection = new Vector.<CanvasLink>();
		}
		
		public function add(link:CanvasLink):void
		{
			collection.push(link);
		}
		
		public function remove(link:CanvasLink):int
		{
			var idx:int = collection.indexOf(link);
			if(idx > -1)
				collection.splice(idx, 1);
			return idx;
		}
		
		public function contains(link:CanvasLink):Boolean
		{
			return collection.indexOf(link) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get VirtualLinks():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each (var cl:CanvasLink in collection)
				links.add(cl.link);
			return links;
		}
		
		public function getForVirtualLinks(links:VirtualLinkCollection):CanvasLinkCollection
		{
			var results:CanvasLinkCollection = new CanvasLinkCollection();
			for each (var cl:CanvasLink in collection)
			{
				if(links.contains(cl.link))
					results.add(cl);
			}
			return results;
		}
		
		public function getForVirtualLink(link:VirtualLink):CanvasLink
		{
			for each (var cl:CanvasLink in collection)
			{
				if(cl.link == link)
					return cl;
			}
			return null;
		}
	}
}