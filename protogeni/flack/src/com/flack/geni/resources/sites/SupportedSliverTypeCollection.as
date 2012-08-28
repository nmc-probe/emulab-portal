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
	import com.flack.geni.resources.SliverTypeCollection;

	public class SupportedSliverTypeCollection
	{
		public var collection:Vector.<SupportedSliverType>;
		public function SupportedSliverTypeCollection()
		{
			collection = new Vector.<SupportedSliverType>();
		}
		
		public function add(supportedType:SupportedSliverType):void
		{
			collection.push(supportedType);
		}
		
		public function remove(supportedType:SupportedSliverType):void
		{
			var idx:int = collection.indexOf(supportedType);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(supportedType:SupportedSliverType):Boolean
		{
			return collection.indexOf(supportedType) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function get SupportsUnbound():Boolean
		{
			for each(var supportedType:SupportedSliverType in collection)
			{
				if(supportedType.supportsUnbound)
					return true;
			}
			return false;
		}
		
		public function get Bound():SupportedSliverTypeCollection
		{
			var supportedTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
			for each(var supportedType:SupportedSliverType in collection)
			{
				if(supportedType.supportsBound)
					supportedTypes.add(supportedType);
			}
			return supportedTypes;
		}
		
		public function get Unbound():SupportedSliverTypeCollection
		{
			var supportedTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
			for each(var supportedType:SupportedSliverType in collection)
			{
				if(supportedType.supportsUnbound)
					supportedTypes.add(supportedType);
			}
			return supportedTypes;
		}
		
		public function get Shared():SupportedSliverTypeCollection
		{
			var supportedTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
			for each(var supportedType:SupportedSliverType in collection)
			{
				if(supportedType.supportsShared)
					supportedTypes.add(supportedType);
			}
			return supportedTypes;
		}
		
		public function get Exclusive():SupportedSliverTypeCollection
		{
			var supportedTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
			for each(var supportedType:SupportedSliverType in collection)
			{
				if(supportedType.supportsExclusive)
					supportedTypes.add(supportedType);
			}
			return supportedTypes;
		}
		
		public function get SliverTypes():SliverTypeCollection
		{
			var slivers:SliverTypeCollection = new SliverTypeCollection();
			for each(var supportedType:SupportedSliverType in collection)
				slivers.add(supportedType.type);
			return slivers;
		}
		
		public function getByName(name:String):SupportedSliverType
		{
			for each(var supportedType:SupportedSliverType in collection)
			{
				if(supportedType.type.name == name)
					return supportedType;
			}
			return null;
		}
		
		// Always returns a valid supported sliver type object. If the sliver
		// is not defined, the returned supported sliver type will have the
		// default settings.
		public function getByNameOrDefault(name:String):SupportedSliverType
		{
			var supportedSliverType:SupportedSliverType = getByName(name);
			if(supportedSliverType != null)
				return supportedSliverType;
			return new SupportedSliverType(name);
		}
		
		public function getOrCreateByName(name:String):SupportedSliverType
		{
			var supportedType:SupportedSliverType = getByName(name);
			if(supportedType == null)
			{
				supportedType = new SupportedSliverType(name)
				add(supportedType);
			}
			return supportedType;
		}
	}
}