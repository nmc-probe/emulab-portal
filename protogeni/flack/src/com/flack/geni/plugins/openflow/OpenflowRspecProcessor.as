package com.flack.geni.plugins.openflow
{
	import com.flack.geni.plugins.RspecProcessInterface;
	import com.flack.geni.resources.SliverType;
	import com.flack.geni.resources.physical.HardwareType;
	import com.flack.geni.resources.physical.PhysicalInterface;
	import com.flack.geni.resources.physical.PhysicalLocation;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.docs.Rspec;
	
	public class OpenflowRspecProcessor implements RspecProcessInterface
	{
		public function OpenflowRspecProcessor()
		{
		}
		
		public function applyFrom(object:*, xml:XML):void
		{
			var manager:GeniManager = object as GeniManager;
			var nodes:XMLList = xml.*::datapath;
			for each(var nodeXml:XML in nodes)
			{
				var node:PhysicalNode = new PhysicalNode(manager, String(nodeXml.@component_id));
				node.name = String(nodeXml.@dpid);
				
				var datapathSliverType:SliverType = new SliverType("openflow-switch");
				node.sliverTypes.add(datapathSliverType);
				
				node.hardwareTypes.add(new HardwareType("openflow-switch"));
				
				// Get location info
				var lat:Number = PhysicalLocation.defaultLatitude;
				var lng:Number = PhysicalLocation.defaultLongitude;
				var country:String = "Unknown";
				
				// Assign to a group based on location
				var location:PhysicalLocation = manager.locations.getAt(lat,lng);
				if(location == null)
				{
					location = new PhysicalLocation(manager, lat, lng, country);
					manager.locations.add(location);
				}
				node.location = location;
				location.nodes.add(node);
				
				node.exclusive = false;
				
				var portsXml:XMLList = nodeXml.*::port;
				for each(var portXml:XML in portsXml)
				{
					var dpPort:PhysicalInterface = new PhysicalInterface(node);
					dpPort.role = PhysicalInterface.ROLE_PORT;
					dpPort.id = IdnUrn.makeFrom(node.id.authority, "port", String(portXml.@name));
					dpPort.num = Number(portXml.@num);
					node.interfaces.add(dpPort);
				}
				
				node.available = node.interfaces.length > 0;
				
				node.advertisement = nodeXml.toXMLString();
				manager.nodes.add(node);
			}
		}
		
		public function applyTo(sliver:Sliver, xml:XML):void
		{
		}
		
		public function get namespace():Namespace
		{
			return new Namespace("openflow", "http://www.geni.net/resources/rspec/ext/openflow/3");
		}
		
		public function get schema():String
		{
			return "http://www.geni.net/resources/rspec/ext/openflow/3 http://www.geni.net/resources/rspec/ext/openflow/3/of-resv.xsd";
		}
	}
}