package com.flack.geni.resources.virtual
{
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.IdnUrn;
	
	public class ComponentHop extends IdentifiableObject
	{
		public var nodeUrn:IdnUrn;
		public var interfaceId:String;
		
		public function ComponentHop(newId:String="", newNodeUrn:String="", newInterfaceId:String="")
		{
			super(newId);
			nodeUrn = new IdnUrn(newNodeUrn);
			interfaceId = newInterfaceId;
		}
	}
}