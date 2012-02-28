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
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;

	/**
	 * Collection of virtual links
	 * 
	 * @author mstrum
	 * 
	 */
	public final class VirtualLinkCollection
	{
		public var collection:Vector.<VirtualLink>
		public function VirtualLinkCollection()
		{
			collection = new Vector.<VirtualLink>();
		}
		
		public function add(l:VirtualLink):void
		{
			collection.push(l);
		}
		
		public function remove(l:VirtualLink):void
		{
			var idx:int = collection.indexOf(l);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(l:VirtualLink):Boolean
		{
			return collection.indexOf(l) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @return New instance of the same collection
		 * 
		 */
		public function get Clone():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
				links.add(link);
			return links;
		}
		
		/**
		 * 
		 * @return Slices for all the links
		 * 
		 */
		public function get Slices():SliceCollection
		{
			var slices:SliceCollection = new SliceCollection();
			for each(var link:VirtualLink in collection)
			{
				if(!slices.contains(link.slice))
					slices.add(link.slice);
			}
			return slices;
		}
		
		/**
		 * 
		 * @return TRUE of any links have unsubmitted changes
		 * 
		 */
		public function get UnsubmittedChanges():Boolean
		{
			for each(var link:VirtualLink in collection)
			{
				if(link.unsubmittedChanges)
					return true;
			}
			return false;
		}
		
		/**
		 * 
		 * @param o Object wanting to use ID
		 * @param id Desired new client ID
		 * @return TRUE if the given object can use the client ID
		 * 
		 */
		public function isIdUnique(o:*, id:String):Boolean
		{
			var found:Boolean = false;
			for each(var testLink:VirtualLink in collection)
			{
				if(o == testLink)
					continue;
				if(testLink.clientId == id)
					return false;
			}
			return true;
		}
		
		/**
		 * 
		 * @param id Client ID
		 * @return Link with the given client ID
		 * 
		 */
		public function getByClientId(id:String):VirtualLink
		{
			for each(var link:VirtualLink in collection)
			{
				if(link.clientId == id)
					return link;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id Sliver ID
		 * @return Link with the given sliver ID
		 * 
		 */
		public function getBySliverId(id:String):VirtualLink
		{
			for each(var link:VirtualLink in collection)
			{
				if(link.id.full == id)
					return link;
			}
			return null;
		}
		
		/**
		 * 
		 * @param slice Slice
		 * @return Links from the given slice
		 * 
		 */
		public function getBySlice(slice:Slice):VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				if(link.slice == slice)
					links.add(link);
			}
			
			return links;
		}
		
		/**
		 * 
		 * @param manager Manager
		 * @return Links connected to the given manager
		 * 
		 */
		public function getConnectedToManager(manager:GeniManager):VirtualLinkCollection
		{
			var connectedLinks:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				if(link.interfaceRefs.Interfaces.Managers.contains(manager) && !connectedLinks.contains(link))
					connectedLinks.add(link);
			}
			return connectedLinks;
		}
		
		/**
		 * 
		 * @param managers Managers
		 * @return Links connected to the given managers
		 * 
		 */
		public function getConnectedToManagers(managers:GeniManagerCollection):VirtualLinkCollection
		{
			var connectedLinks:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				var linkManagers:GeniManagerCollection = link.interfaceRefs.Interfaces.Managers;
				var valid:Boolean = true;
				for each(var linkedManager:GeniManager in linkManagers.collection)
				{
					if(!managers.contains(linkedManager))
					{
						valid = false;
						break;
					}
				}
				if(!valid)
					break;
				if(!connectedLinks.contains(link))
					connectedLinks.add(link);
			}
			return connectedLinks;
		}
		
		/**
		 * 
		 * @param nodes Virtual nodes
		 * @return Links connected to the given nodes
		 * 
		 */
		public function getConnectedToNodes(nodes:VirtualNodeCollection):VirtualLinkCollection
		{
			var connectedLinks:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				var linkNodes:VirtualNodeCollection = link.interfaceRefs.Interfaces.Nodes;
				if(linkNodes.length == nodes.length)
				{
					var found:Boolean = true;
					for each(var linkNode:VirtualNode in linkNodes.collection)
					{
						if(!nodes.contains(linkNode))
							found = false;
					}
					if(found)
						connectedLinks.add(link);
				}
			}
			return connectedLinks;
		}
		
		/**
		 * 
		 * @param node Virtual node
		 * @return Links connected to the given node
		 * 
		 */
		public function getConnectedToNode(node:VirtualNode):VirtualLinkCollection
		{
			var connectedLinks:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				if(link.interfaceRefs.Interfaces.Nodes.contains(node))
					connectedLinks.add(link);
			}
			return connectedLinks;
		}
		
		/**
		 * 
		 * @param type Link type
		 * @return Links of the given type
		 * 
		 */
		public function getByType(type:String):VirtualLinkCollection
		{
			var group:VirtualLinkCollection = new VirtualLinkCollection();
			for each (var l:VirtualLink in collection)
			{
				if(l.type.name == type)
					group.add(l);
			}
			return group;
		}
		
		/**
		 * 
		 * @return Interfaces used in the links
		 * 
		 */
		public function get Interfaces():VirtualInterfaceCollection
		{
			var interfaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
			for each(var link:VirtualLink in collection)
			{
				for each(var linkInterface:VirtualInterface in link.interfaceRefs.Interfaces.collection)
				{
					if(!interfaces.contains(linkInterface))
						interfaces.add(linkInterface);
				}
			}
			return interfaces;
		}
		
		/**
		 * 
		 * @return Maximum capacity found in any one path
		 * 
		 */
		public function get MaximumCapacity():Number
		{
			var max:Number = 0;
			for each(var link:VirtualLink in collection)
			{
				var linkCapacity:Number = link.Capacity;
				if(linkCapacity > max)
					max = linkCapacity;
			}
			return max;
		}
		
		/**
		 * 
		 * @return Types of links
		 * 
		 */
		public function get Types():Vector.<String>
		{
			var types:Vector.<String> = new Vector.<String>();
			for each(var link:VirtualLink in collection)
			{
				if(types.indexOf(link.type.name) == -1)
					types.push(link.type.name);
			}
			return types.sort(
				function compareTypes(a:String, b:String):Number
				{
					if(a < b)
						return -1;
					else if(a == b)
						return 0;
					else
						return 1;
				});
		}
	}
}