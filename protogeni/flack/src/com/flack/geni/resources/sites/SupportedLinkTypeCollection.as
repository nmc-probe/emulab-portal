package com.flack.geni.resources.sites
{
	public class SupportedLinkTypeCollection
	{
		public var collection:Vector.<SupportedLinkType>;
		public function SupportedLinkTypeCollection()
		{
			collection = new Vector.<SupportedLinkType>();
		}
		
		public function add(supportedType:SupportedLinkType):void
		{
			collection.push(supportedType);
		}
		
		public function remove(supportedType:SupportedLinkType):void
		{
			var idx:int = collection.indexOf(supportedType);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(supportedType:SupportedLinkType):Boolean
		{
			return collection.indexOf(supportedType) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		public function getByName(name:String):SupportedLinkType
		{
			for each(var supportedType:SupportedLinkType in collection)
			{
				if(supportedType.name == name)
					return supportedType;
			}
			return null;
		}
		
		public function getOrCreateByName(name:String):SupportedLinkType
		{
			var supportedType:SupportedLinkType = getByName(name);
			if(supportedType == null)
			{
				supportedType = new SupportedLinkType(name)
				add(supportedType);
			}
			return supportedType;
		}
	}
}