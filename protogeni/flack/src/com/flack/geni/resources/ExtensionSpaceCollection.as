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

package com.flack.geni.resources
{
	/**
	 * Collection of extension spaces
	 * 
	 * @author mstrum
	 * 
	 */
	public class ExtensionSpaceCollection
	{
		public var collection:Vector.<ExtensionSpace> = new Vector.<ExtensionSpace>();
		public function ExtensionSpaceCollection()
		{
			collection = new Vector.<ExtensionSpace>();
		}
		
		public function add(s:ExtensionSpace):void
		{
			collection.push(s);
		}
		
		public function remove(s:ExtensionSpace):void
		{
			var idx:int = collection.indexOf(s);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get Namespaces():Vector.<Namespace>
		{
			var namespaces:Vector.<Namespace> = new Vector.<Namespace>();
			for each(var space:ExtensionSpace in collection)
				namespaces.push(space.namespace);
			return namespaces;
		}
		
		public function getForNamespace(namespace:Namespace):ExtensionSpace
		{
			for each(var space:ExtensionSpace in collection)
			{
				if(space.namespace == namespace)
					return space;
			}
			return null;
		}
	}
}