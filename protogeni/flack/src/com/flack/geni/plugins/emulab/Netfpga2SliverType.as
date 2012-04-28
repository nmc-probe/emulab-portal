package com.flack.geni.plugins.emulab
{
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.plugins.SliverTypePart;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;
	
	public class Netfpga2SliverType implements SliverTypeInterface
	{
		static public const TYPE_NETFPGA2:String = "netfpga2";
		
		public function Netfpga2SliverType()
		{
		}
		
		public function get Name():String { return TYPE_NETFPGA2; }
		
		public function get namespace():Namespace
		{
			return null;
		}
		
		public function get schema():String
		{
			return "";
		}
		
		public function get Part():SliverTypePart
		{
			return null;
		}
		
		public function get Clone():SliverTypeInterface
		{
			var clone:Netfpga2SliverType = new Netfpga2SliverType();
			return clone;
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
			return true;
		}
		
		public function get SimpleList():ArrayCollection
		{
			return null;
		}
	}
}