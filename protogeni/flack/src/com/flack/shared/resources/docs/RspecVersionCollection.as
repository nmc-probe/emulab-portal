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

package com.flack.shared.resources.docs
{
	/**
	 * List of RSPEC versions
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RspecVersionCollection
	{
		public var collection:Vector.<RspecVersion> = new Vector.<RspecVersion>();
		public function RspecVersionCollection(src:Array = null)
		{
			collection = new Vector.<RspecVersion>();
			if(src != null)
			{
				for each(var old:RspecVersion in src)
					collection.push(old);
			}
		}
		
		public function add(s:RspecVersion):void
		{
			collection.push(s);
		}
		
		public function remove(s:RspecVersion):void
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
		 * 
		 * @return RSPEC versions Flack can use from the collection
		 * 
		 */
		public function get UsableRspecVersions():RspecVersionCollection
		{
			var results:RspecVersionCollection = new RspecVersionCollection();
			for each(var rspecVersion:RspecVersion in collection)
			{
				if(rspecVersion.type == RspecVersion.TYPE_GENI || rspecVersion.type == RspecVersion.TYPE_PROTOGENI)
					results.add(rspecVersion);
			}
			return results;
		}
		
		/**
		 * Gets the RSPEC version based on the given values
		 * 
		 * @param type Type of rspec to return
		 * @param version Version of rspec to return
		 * @return RSPEC version based on the given information
		 * 
		 */
		public function get(type:String, version:Number):RspecVersion
		{
			for each(var rspecVersion:RspecVersion in collection)
			{
				if(rspecVersion.type == type && rspecVersion.version == version)
					return rspecVersion;
			}
			return null;
		}
		
		/**
		 * Get all RSPEC versions of the given type
		 * 
		 * @param type Type of RSPEC to return
		 * @return Collection of RSPEC versions of the given type
		 * 
		 */
		public function getByType(type:String):RspecVersionCollection
		{
			var results:RspecVersionCollection = new RspecVersionCollection();
			for each(var rspecVersion:RspecVersion in collection)
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
			for each(var rspecVersion:RspecVersion in collection)
			{
				if(types.indexOf(rspecVersion.type) == -1)
					types.push(rspecVersion.type);
			}
			return types;
		}
		
		/**
		 * 
		 * @return Highest version
		 * 
		 */
		public function get MaxVersion():RspecVersion
		{
			var maxVersion:RspecVersion = null;
			for each(var rspecVersion:RspecVersion in collection)
			{
				if(maxVersion == null || maxVersion.version < rspecVersion.version)
					maxVersion = rspecVersion;
			}
			return maxVersion;
		}
	}
}