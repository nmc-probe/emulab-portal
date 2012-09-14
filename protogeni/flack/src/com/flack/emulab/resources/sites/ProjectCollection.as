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

package com.flack.emulab.resources.sites
{
	/**
	 * Collection of hardware types
	 * @author mstrum
	 * 
	 */
	public class ProjectCollection
	{
		public var collection:Vector.<Project>;
		public function ProjectCollection()
		{
			collection = new Vector.<Project>();
		}
		
		public function add(ht:Project):void
		{
			collection.push(ht);
		}
		
		public function remove(ht:Project):void
		{
			var idx:int = collection.indexOf(ht);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(ht:Project):Boolean
		{
			return collection.indexOf(ht) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
	}
}