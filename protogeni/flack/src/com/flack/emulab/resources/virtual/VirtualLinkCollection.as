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
	/**
	 * Collection of slices
	 * 
	 * @author mstrum
	 * 
	 */
	public final class VirtualLinkCollection
	{
		public var collection:Vector.<VirtualLink>;
		public function VirtualLinkCollection()
		{
			collection = new Vector.<VirtualLink>();
		}
		
		public function add(slice:VirtualLink):void
		{
			collection.push(slice);
		}
		
		public function remove(slice:VirtualLink):void
		{
			var idx:int = collection.indexOf(slice);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(slice:VirtualLink):Boolean
		{
			return collection.indexOf(slice) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get Clone():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
				links.add(link);
			return links;
		}
		
		public function get UnsubmittedChanges():Boolean
		{
			for each(var link:VirtualLink in collection)
			{
				if(link.unsubmittedChanges)
					return true;
			}
			return false;
		}
		
		public function get Experiments():ExperimentCollection
		{
			var experiments:ExperimentCollection = new ExperimentCollection();
			for each(var link:VirtualLink in collection)
			{
				if(!experiments.contains(link.experiment))
					experiments.add(link.experiment);
			}
			return experiments;
		}
		
		public function get Interfaces():VirtualInterfaceCollection
		{
			var interfaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
			for each(var link:VirtualLink in collection)
			{
				for each(var linkInterface:VirtualInterface in link.interfaces.collection)
				{
					if(!interfaces.contains(linkInterface))
						interfaces.add(linkInterface);
				}
			}
			return interfaces;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Slice with the given ID
		 * 
		 */
		public function getByName(name:String):VirtualLink
		{
			for each(var existing:VirtualLink in collection)
			{
				if(existing.name == name)
					return existing;
			}
			return null;
		}
		
		public function isIdUnique(o:*, name:String):Boolean
		{
			var found:Boolean = false;
			for each(var testLink:VirtualLink in collection)
			{
				if(o == testLink)
					continue;
				if(testLink.name == name)
					return false;
			}
			return true;
		}
		
		public function getByExperiment(exp:Experiment):VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				if(link.experiment == exp)
					links.add(link);
			}
			
			return links;
		}
		
		public function getConnectedToNodes(nodes:VirtualNodeCollection):VirtualLinkCollection
		{
			var connectedLinks:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				var linkNodes:VirtualNodeCollection = link.interfaces.Nodes;
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
		
		public function getConnectedToNode(node:VirtualNode):VirtualLinkCollection
		{
			var connectedLinks:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var link:VirtualLink in collection)
			{
				if(link.interfaces.Nodes.contains(node))
					connectedLinks.add(link);
			}
			return connectedLinks;
		}
	}
}