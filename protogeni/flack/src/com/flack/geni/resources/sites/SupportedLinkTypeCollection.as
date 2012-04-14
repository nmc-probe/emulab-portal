package com.flack.geni.resources.sites
{
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;

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
		
		public function get Clone():SupportedLinkTypeCollection
		{
			var clone:SupportedLinkTypeCollection = new SupportedLinkTypeCollection();
			for each(var supportedType:SupportedLinkType in collection)
				clone.add(supportedType);
			return clone;
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
		
		public function supportedFor(nodes:VirtualNodeCollection):SupportedLinkTypeCollection
		{
			var supportedTypes:SupportedLinkTypeCollection = Clone;
			for each(var node:VirtualNode in nodes.collection)
			{
				if(node.manager.supportedSliverTypes.getByName(node.sliverType.name).limitToLinkType.length > 0)
				{
					var supportedType:SupportedLinkType = supportedTypes.getByName(node.manager.supportedSliverTypes.getByName(node.sliverType.name).limitToLinkType);
					supportedTypes = new SupportedLinkTypeCollection();
					if(supportedType != null)
						supportedTypes.add(supportedType);
					else
						return supportedTypes;
				}
			}
			return supportedTypes;
		}
		
		public function preferredType(numConnections:int = int.MAX_VALUE):SupportedLinkType
		{
			var preferred:SupportedLinkType = null;
			if(length > 0)
			{
				for(var i:int = 0; i < length; i++)
				{
					var testType:SupportedLinkType = collection[i];
					if(testType.maxConnections >= numConnections && (preferred == null || testType.level < preferred.level))
						preferred = testType;
				}
			}
			return preferred;
		}
	}
}