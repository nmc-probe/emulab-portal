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

package com.flack.geni.resources.docs
{
	/**
	 * List of RSPEC versions
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GeniCredentialVersionCollection
	{
		public var collection:Vector.<GeniCredentialVersion> = new Vector.<GeniCredentialVersion>();
		public function GeniCredentialVersionCollection(src:Array = null)
		{
			collection = new Vector.<GeniCredentialVersion>();
			if(src != null)
			{
				for each(var old:GeniCredentialVersion in src)
					collection.push(old);
			}
		}
		
		public function add(s:GeniCredentialVersion):void
		{
			collection.push(s);
		}
		
		public function remove(s:GeniCredentialVersion):void
		{
			var idx:int = collection.indexOf(s);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * Get all RSPEC versions of the given type
		 * 
		 * @param type Type of RSPEC to return
		 * @return Collection of RSPEC versions of the given type
		 * 
		 */
		public function getByType(type:String):GeniCredentialVersionCollection
		{
			var results:GeniCredentialVersionCollection = new GeniCredentialVersionCollection();
			for each(var rspecVersion:GeniCredentialVersion in collection)
			{
				if(rspecVersion.type == type)
					results.add(rspecVersion);
			}
			return results;
		}
		
		/**
		 * 
		 * @return RSPEC types in the collection
		 * 
		 */
		public function get Types():Vector.<String>
		{
			var types:Vector.<String> = new Vector.<String>();
			for each(var rspecVersion:GeniCredentialVersion in collection)
			{
				if(types.indexOf(rspecVersion.type) == -1)
					types.push(rspecVersion.type);
			}
			return types;
		}
	}
}