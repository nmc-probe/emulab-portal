package com.flack.geni.plugins.shadownet
{
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.plugins.SliverTypePart;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;
	
	public class JuniperRouterSliverType implements SliverTypeInterface
	{
		static public var TYPE_JUNIPER_LROUTER:String = "juniper-lrouter";
		
		public function JuniperRouterSliverType()
		{
		}
		
		public function get Clone():SliverTypeInterface
		{
			return null;
		}
		
		public function applyToSliverTypeXml(node:VirtualNode, xml:XML):void
		{
		}
		
		public function applyFromAdvertisedSliverTypeXml(node:PhysicalNode, xml:XML):void
		{
		}
		
		public function applyFromSliverTypeXml(node:VirtualNode, xml:XML):void
		{
		}
		
		public function interfaceRemoved(iface:VirtualInterface):void
		{
		}
		
		public function interfaceAdded(iface:VirtualInterface):void
		{
		}
		
		public function canAdd(node:VirtualNode):Boolean
		{
			return false;
		}
		
		public function get SimpleList():ArrayCollection
		{
			return null;
		}
		
		public function get namespace():Namespace
		{
			return null;
		}
		
		public function get schema():String
		{
			return null;
		}
		
		public function get Name():String
		{
			return null;
		}
		
		public function get Part():SliverTypePart
		{
			return null;
		}
	}
}