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