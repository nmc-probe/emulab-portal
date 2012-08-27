package com.flack.geni.plugins.planetlab
{
	import com.flack.geni.RspecUtil;
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.plugins.SliverTypePart;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;

	// To be subclassed.
	public class OpenStackSliverType implements SliverTypeInterface
	{
		public var fwRules:Vector.<FwRule> = null;
		
		public function OpenStackSliverType()
		{
		}
		
		public function get Name():String { return ""; }
		
		public function get namespace():Namespace
		{
			return new Namespace("plos", "http://www.planet-lab.org/resources/sfa/ext/plos/1");
		}
		
		public function get schema():String
		{
			return "";
		}
		
		public function get Part():SliverTypePart { return new OpenStackVgroup; }
		
		public function get Clone():SliverTypeInterface
		{
			var clone:OpenStackSliverType = new OpenStackSliverType();
			if(fwRules != null)
			{
				clone.fwRules = new Vector.<FwRule>();
				for each(var fwRule:FwRule in fwRules)
					clone.fwRules.push(new FwRule(fwRule.protocol, fwRule.portRange, fwRule.cidrIp));
			}
			return clone;
		}
		
		public function get SimpleList():ArrayCollection
		{
			var list:ArrayCollection = new ArrayCollection();
			if(fwRules != null)
			{
				for each(var fwRule:FwRule in fwRules)
					list.addItem(fwRule.ToString());
			}
			return list;
		}
		
		public function canAdd(node:VirtualNode):Boolean
		{
			return true;
		}
		
		public function applyToSliverTypeXml(node:VirtualNode, xml:XML):void
		{
			if(fwRules != null)
			{
				for each(var fwRule:FwRule in fwRules)
				{
					var fwRuleXml:XML = new XML("<fw_rule />");
					if(fwRule.protocol.length > 0)
						fwRuleXml.@protocol = fwRule.protocol;
					if(fwRule.portRange.length > 0)
						fwRuleXml.@port_range = fwRule.portRange;
					if(fwRule.cidrIp.length > 0)
						fwRuleXml.@cidr_ip = fwRule.cidrIp;
					fwRuleXml.setNamespace(namespace);
					xml.appendChild(fwRuleXml);
				}
			}
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
	}
}