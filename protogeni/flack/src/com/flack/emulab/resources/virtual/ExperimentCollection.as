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
	public final class ExperimentCollection
	{
		public var collection:Vector.<Experiment>;
		public function ExperimentCollection()
		{
			collection = new Vector.<Experiment>();
		}
		
		public function add(slice:Experiment):void
		{
			collection.push(slice);
		}
		
		public function remove(slice:Experiment):void
		{
			var idx:int = collection.indexOf(slice);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(slice:Experiment):Boolean
		{
			return collection.indexOf(slice) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Slice with the given ID
		 * 
		 */
		public function getByName(name:String):Experiment
		{
			for each(var existing:Experiment in collection)
			{
				if(existing.name == name)
					return existing;
			}
			return null;
		}
		
		
		/**
		 * 
		 * @return Nodes from all the slices
		 * 
		public function get Nodes():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			return nodes;
		}
		
		public function get Links():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			return links;
		}
		*/
	}
}