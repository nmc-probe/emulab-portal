package com.flack.geni.plugins
{
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;

	public interface SliverTypeInterface
	{
		function get Name():String;
		// Optional
		function get namespace():Namespace;
		function get schema():String;
		
		function get Clone():SliverTypeInterface;
		
		function applyToSliverTypeXml(node:VirtualNode, xml:XML):void;
		function applyFromAdvertisedSliverTypeXml(node:PhysicalNode, xml:XML):void;
		function applyFromSliverTypeXml(node:VirtualNode, xml:XML):void;
		
		// Hooks
		function interfaceRemoved(iface:VirtualInterface):void;
		function interfaceAdded(iface:VirtualInterface):void;
		function canAdd(node:VirtualNode):Boolean;
		
		// List of strings when listing sliver type values
		function get SimpleList():ArrayCollection;
		
		// Optional custom node sliver type options interface
		function get Part():SliverTypePart;
	}
}