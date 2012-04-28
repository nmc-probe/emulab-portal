package com.flack.geni.plugins.emulab
{
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.plugins.SliverTypePart;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;
	
	public class EmulabSppSliverType implements SliverTypeInterface
	{
		static public const TYPE_EMULAB_SPP:String = "emulab-spp";
		
		public function EmulabSppSliverType()
		{
		}
		
		public function get Name():String { return TYPE_EMULAB_SPP; }
		
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
			var clone:EmulabSppSliverType = new EmulabSppSliverType();
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