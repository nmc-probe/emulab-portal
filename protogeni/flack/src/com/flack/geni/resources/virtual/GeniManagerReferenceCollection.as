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
	 * Collection of references to managers
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniManagerReferenceCollection
	{
		public var collection:Vector.<GeniManagerReference>;
		public function GeniManagerReferenceCollection()
		{
			collection = new Vector.<GeniManagerReference>();
		}
		
		public function add(referencedManager:*):void
		{
			if(referencedManager is GeniManagerReference)
				collection.push(referencedManager);
			else if(referencedManager is GeniManager)
				collection.push(new GeniManagerReference(referencedManager));
		}
		
		public function remove(referencedManager:*):void
		{
			var idx:int = -1;
			if(referencedManager is GeniManagerReference)
				idx = collection.indexOf(referencedManager);
			else if(referencedManager is GeniManager)
			{
				for each(var ref:GeniManagerReference in collection)
				{
					if(ref.referencedManager == referencedManager)
					{
						idx = collection.indexOf(ref);
						break;
					}
				}
			}
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(referencedManager:*):Boolean
		{
			if(referencedManager is GeniManagerReference)
				return collection.indexOf(referencedManager) > -1;
			else if(referencedManager is GeniManager)
			{
				for each(var ref:GeniManagerReference in collection)
				{
					if(ref.referencedManager == referencedManager)
						return true;
				}
			}
			return false;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @return Collection of managers referenced
		 * 
		 */
		public function get Managers():GeniManagerCollection
		{
			var managers:GeniManagerCollection = new GeniManagerCollection();
			for each(var managerRef:GeniManagerReference in collection)
				managers.add(managerRef.referencedManager);
			return managers;
		}
		
		/**
		 * 
		 * @param manager Manager we want the reference for
		 * @return Reference to the given manager
		 * 
		 */
		public function getReferenceFor(manager:GeniManager):GeniManagerReference
		{
			for each(var managerRef:GeniManagerReference in collection)
			{
				if(managerRef.referencedManager == manager)
					return managerRef;
			}
			return null;
		}
	}
}