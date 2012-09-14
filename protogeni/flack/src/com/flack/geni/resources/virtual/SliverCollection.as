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
	 * Collection of slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public final class SliverCollection
	{
		public var collection:Vector.<Sliver>;
		public function SliverCollection()
		{
			collection = new Vector.<Sliver>();
		}
		
		public function add(s:Sliver):void
		{
			collection.push(s);
		}
		
		public function remove(s:Sliver):void
		{
			var idx:int = collection.indexOf(s);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(s:Sliver):Boolean
		{
			return collection.indexOf(s) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @return New instance with the same collection
		 * 
		 */
		public function get Clone():SliverCollection
		{
			var clone:SliverCollection = new SliverCollection();
			for each(var sliver:Sliver in collection)
				clone.add(sliver);
			return clone;
		}
		
		/**
		 * 
		 * @return Slivers which have allocated resources
		 * 
		 */
		public function get Created():SliverCollection
		{
			var created:SliverCollection = new SliverCollection();
			for each(var sliver:Sliver in collection)
			{
				if(sliver.Created)
					created.add(sliver);
			}
			return created;
		}
		
		/**
		 * Removes slivers which aren't created and don't have resources
		 * 
		 */
		public function cleanup():void
		{
			for(var i:int = 0; i < collection.length; i++)
			{
				var sliver:Sliver = collection[i];
				if(!sliver.Created && sliver.Nodes.length == 0)
				{
					remove(sliver);
					i--;
				}
			}
		}
		
		/**
		 * 
		 * @param id Sliver ID
		 * @return Sliver with the given sliver ID
		 * 
		 */
		public function getBySliverId(id:String):Sliver
		{
			for each(var sliver:Sliver in collection)
			{
				if(sliver.id.full == id)
					return sliver;
			}
			return null;
		}
		
		/**
		 * 
		 * @param gm Manager
		 * @return Sliver for the manager
		 * 
		 */
		public function getByManager(gm:GeniManager):Sliver
		{
			for each(var sliver:Sliver in collection)
			{
				if(sliver.manager == gm)
					return sliver;
			}
			return null;
		}
		
		/**
		 * 
		 * @param gmc Managers
		 * @return Slivers for the given managers
		 * 
		 */
		public function getByManagers(gmc:GeniManagerCollection):SliverCollection
		{
			var sc:SliverCollection = new SliverCollection();
			for each(var sliver:Sliver in collection)
			{
				if(gmc.contains(sliver.manager))
					sc.add(sliver);
			}
			return sc;
		}
		
		/**
		 * 
		 * @param gm Manager
		 * @param slice Slice
		 * @return Sliver for the given manager in the slice and guarenteed to be added in the slice
		 * 
		 */
		public function getOrCreateByManager(gm:GeniManager, slice:Slice):Sliver
		{
			var newSliver:Sliver = getByManager(gm);
			if(newSliver != null)
				return newSliver;
			else
			{
				newSliver = new Sliver(slice, gm);
				add(newSliver);
				return newSliver;
			}
		}
		
		/**
		 * 
		 * @return Earliest expiration date from the slice and slivers
		 * 
		 */
		public function get EarliestExpiration():Date
		{
			var d:Date = null;
			for each(var sliver:Sliver in collection)
			{
				if(d == null || (sliver.Created && sliver.expires < d))
					d = sliver.expires;
			}
			return d;
		}
		
		/**
		 * 
		 * @return TRUE if any sliver has allocated resources
		 * 
		 */
		public function get AllocatedAnyResources():Boolean
		{
			for each(var sliver:Sliver in collection)
			{
				if(sliver.Created)
					return true;
			}
			return false;
		}
	}
}