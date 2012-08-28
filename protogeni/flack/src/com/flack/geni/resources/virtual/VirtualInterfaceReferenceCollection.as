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
	/**
	 * Collection of interface references
	 * 
	 * @author mstrum
	 * 
	 */
	public class VirtualInterfaceReferenceCollection
	{
		[Bindable]
		public var collection:Vector.<VirtualInterfaceReference>;
		public function VirtualInterfaceReferenceCollection()
		{
			collection = new Vector.<VirtualInterfaceReference>();
		}
		
		public function add(virtualInterface:*):void
		{
			if(virtualInterface is VirtualInterfaceReference)
				collection.push(virtualInterface);
			else if(virtualInterface is VirtualInterface)
				collection.push(new VirtualInterfaceReference(virtualInterface));
		}
		
		public function remove(virtualInterface:*):void
		{
			var idx:int = -1;
			if(virtualInterface is VirtualInterfaceReference)
				idx = collection.indexOf(virtualInterface);
			else if(virtualInterface is VirtualInterface)
			{
				for each(var ref:VirtualInterfaceReference in collection)
				{
					if(ref.referencedInterface == virtualInterface)
					{
						idx = collection.indexOf(ref);
						break;
					}
				}
			}
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(virtualInterface:*):Boolean
		{
			if(virtualInterface is VirtualInterfaceReference)
				return collection.indexOf(virtualInterface) > -1;
			else if(virtualInterface is VirtualInterface)
			{
				for each(var ref:VirtualInterfaceReference in collection)
				{
					if(ref.referencedInterface == virtualInterface)
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
		 * @return Virtual interfaces being referenced
		 * 
		 */
		public function get Interfaces():VirtualInterfaceCollection
		{
			var interfaces:VirtualInterfaceCollection = new VirtualInterfaceCollection();
			for each(var interfaceRef:VirtualInterfaceReference in collection)
				interfaces.add(interfaceRef.referencedInterface);
			return interfaces;
		}
		
		/**
		 * 
		 * @param iface Virtual interface
		 * @return Reference to given virtual interface
		 * 
		 */
		public function getReferenceFor(iface:VirtualInterface):VirtualInterfaceReference
		{
			for each(var interfaceRef:VirtualInterfaceReference in collection)
			{
				if(interfaceRef.referencedInterface == iface)
					return interfaceRef;
			}
			return null;
		}
	}
}