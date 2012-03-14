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
	public class OsidCollection
	{
		public var collection:Vector.<Osid>;
		public function OsidCollection()
		{
			collection = new Vector.<Osid>();
		}
		
		public function add(ht:Osid):void
		{
			var htName:String = ht.name.toLowerCase();
			for(var i:int = 0; i < collection.length; i++)
			{
				if(collection[i].name.toLowerCase() > htName)
				{
					collection.splice(i, 0, ht);
					return;
				}
			}
			collection.push(ht);
		}
		
		public function remove(ht:Osid):void
		{
			var idx:int = collection.indexOf(ht);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(ht:Osid):Boolean
		{
			return collection.indexOf(ht) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function getByName(name:String):Osid
		{
			for each(var osid:Osid in collection)
			{
				if(osid.name == name)
					return osid;
			}
			return null;
		}
		
		public function searchByName(name:String):OsidCollection
		{
			var searchName:String = name.toLowerCase();
			var osids:OsidCollection = new OsidCollection();
			for each (var o:Osid in collection)
			{
				if(o.name.toLowerCase().indexOf(searchName) != -1)
					osids.add(o);
			}
			return osids;
		}
	}
}