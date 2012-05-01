package com.flack.geni.plugins.planetlab
{
	import com.flack.geni.RspecUtil;
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.plugins.SliverTypePart;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.geni.resources.virtual.VirtualNode;
	
	import mx.collections.ArrayCollection;

	public class PlanetlabSliverType implements SliverTypeInterface
	{
		static public const TYPE_PLANETLAB_V1:String = "plab-vnode";
		static public const TYPE_PLANETLAB_V2:String = "plab-vserver";
		
		public var initscripts:Vector.<String> = null;
		public var selectedInitscript:String = "";
		
		public function PlanetlabSliverType()
		{
		}
		
		public function get Name():String { return TYPE_PLANETLAB_V2; }
		
		public function get namespace():Namespace
		{
			return new Namespace("planetlab", "http://www.planet-lab.org/resources/sfa/ext/planetlab/1");
		}
		
		public function get schema():String
		{
			return "";
		}
		
		public function get Part():SliverTypePart { return new PlanetlabVgroup(); }
		
		public function get Clone():SliverTypeInterface
		{
			var clone:PlanetlabSliverType = new PlanetlabSliverType();
			if(initscripts != null)
			{
				clone.initscripts = new Vector.<String>();
				for each(var iscript:String in initscripts)
					clone.initscripts.push(iscript);
			}
			clone.selectedInitscript = selectedInitscript;
			return clone;
		}
		
		public function get SimpleList():ArrayCollection
		{
			var list:ArrayCollection = new ArrayCollection();
			if(initscripts != null)
			{
				for each(var initScript:String in initscripts)
					list.addItem(initScript);
			}
			return list;
		}
		
		public function canAdd(node:VirtualNode):Boolean
		{
			return true;
		}
		
		public function applyToSliverTypeXml(node:VirtualNode, xml:XML):void
		{
			var planetlabInitscriptXml:XML = new XML("<initscript name=\""+selectedInitscript+"\" />");
			planetlabInitscriptXml.setNamespace(namespace);
			xml.appendChild(planetlabInitscriptXml);
		}
		
		public function applyFromAdvertisedSliverTypeXml(node:PhysicalNode, xml:XML):void
		{
			applyFromSliverTypeXml(null, xml);
		}
		
		public function applyFromSliverTypeXml(node:VirtualNode, xml:XML):void
		{
			for each(var sliverTypeChild:XML in xml.children())
			{
				if(sliverTypeChild.namespace() == namespace)
				{
					if(sliverTypeChild.localName() == "initscript")
					{
						if(node == null)
						{
							if(initscripts == null)
								initscripts = new Vector.<String>();
							initscripts.push(String(sliverTypeChild.@name));
						}
						else
							selectedInitscript = String(sliverTypeChild.@name);
					}
					
				}
			}
		}
		
		public function interfaceRemoved(iface:VirtualInterface):void
		{
		}
		
		public function interfaceAdded(iface:VirtualInterface):void
		{
		}
	}
}