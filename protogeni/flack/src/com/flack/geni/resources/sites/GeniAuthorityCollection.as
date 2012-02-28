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

package com.flack.geni.resources.sites
{
	/**
	 * Collection of geni authorities
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniAuthorityCollection
	{
		public var collection:Vector.<GeniAuthority>;
		public function GeniAuthorityCollection()
		{
			collection = new Vector.<GeniAuthority>();
		}
		
		public function add(authority:GeniAuthority):void
		{
			collection.push(authority);
		}
		
		public function remove(authority:GeniAuthority):void
		{
			var idx:int = collection.indexOf(authority);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(authority:GeniAuthority):Boolean
		{
			return collection.indexOf(authority) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param url URL for authority we are looking for
		 * @return Authority with the given url
		 * 
		 */
		public function getByUrl(url:String):GeniAuthority
		{
			for each(var authority:GeniAuthority in collection)
			{
				if(authority.url == url)
					return authority;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Authority with the given ID
		 * 
		 */
		public function getById(id:String):GeniAuthority
		{
			for each(var authority:GeniAuthority in collection)
			{
				if(authority.id.full == id)
					return authority;
			}
			return null;
		}
		
		/**
		 * 
		 * @param name Authority of the IDN-URN
		 * @return Authority with a matching authority part of the ID
		 * 
		 */
		public function getByAuthority(name:String):GeniAuthority
		{
			for each(var authority:GeniAuthority in collection)
			{
				if(authority.id.authority == name)
					return authority;
			}
			return null;
		}
	}
}