/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

package com.flack.geni.resources.physical
{
	import com.flack.geni.RspecUtil;
	import com.flack.shared.utils.StringUtil;

	/**
	 * Collection of physical locations
	 * 
	 * @author mstrum
	 * 
	 */
	public class PhysicalLocationCollection
	{
		public var collection:Vector.<PhysicalLocation>;
		public function PhysicalLocationCollection()
		{
			collection = new Vector.<PhysicalLocation>();
		}
		
		public function add(location:PhysicalLocation):void
		{
			collection.push(location);
		}
		
		public function remove(location:PhysicalLocation):void
		{
			var idx:int = collection.indexOf(location);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(location:PhysicalLocation):Boolean
		{
			return collection.indexOf(location) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @param lat Latitude
		 * @param lng Longitude
		 * @return Physical location located at the given coordinates
		 * 
		 */
		public function getAt(lat:Number, lng:Number):PhysicalLocation
		{
			for each(var location:PhysicalLocation in collection)
			{
				if(location.latitude == lat && location.longitude == lng)
					return location;
			}
			return null;
		}
		
		/**
		 * 
		 * @return Physical location representing the middle of all the locations
		 * 
		 */
		public function get Middle():PhysicalLocation
		{
			var middleLatitude:Number = 0;
			var middleLongitude:Number = 0;
			for each(var location:PhysicalLocation in collection)
			{
				middleLatitude += location.latitude;
				middleLongitude += location.longitude;
			}
			return new PhysicalLocation(null, middleLatitude/collection.length, middleLongitude/collection.length);
		}
		
		/**
		 * 
		 * @return GraphML representation
		 * 
		 */
		public function get GraphML():String
		{
			var graphMl:XML = new XML("<?xml version=\"1.0\" encoding=\"UTF-8\"?><graphml />");
			var graphMlNamespace:Namespace = new Namespace(null, "http://graphml.graphdrawing.org/xmlns");
			graphMl.setNamespace(graphMlNamespace);
			var xsiNamespace:Namespace = RspecUtil.xsiNamespace;
			graphMl.addNamespace(xsiNamespace);
			graphMl.@xsiNamespace::schemaLocation = "http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd";
			graphMl.@id = "Flack GraphML";
			graphMl.@edgedefault = "undirected";
			
			for each(var location:PhysicalLocation in collection)
			{
				for each(var node:PhysicalNode in location.nodes.collection)
				{
					var nodeXml:XML = <node />;
					nodeXml.@id = node.id;
					nodeXml.@name = node.name;
					for each(var nodeInterface:PhysicalInterface in node.interfaces.collection)
					{
						var nodeInterfaceXml:XML = <port />;
						nodeInterfaceXml.@name = nodeInterface.id;
						nodeXml.appendChild(nodeInterfaceXml);
					}
					graphMl.appendChild(nodeXml);
				}
				
				for each(var link:PhysicalLink in location.links.collection)
				{
					var hyperedgeXml:XML = <hyperedge />;
					hyperedgeXml.@id = link.id;
					for each(var linkInterface:PhysicalInterface in link.interfaces.collection)
					{
						var endpointXml:XML = <endpoint />;
						endpointXml.@node = linkInterface.owner.id;
						endpointXml.@port = linkInterface.id;
						hyperedgeXml.appendChild(endpointXml);
					}
					graphMl.appendChild(hyperedgeXml);
				}
			}
			
			return graphMl;
		}
		
		/**
		 * 
		 * @return DOT graph representation
		 * 
		 */
		public function get DotGraph():String
		{
			var dot:String = "graph Flack {";
			
			for each(var location:PhysicalLocation in collection)
			{
				for each(var node:PhysicalNode in location.nodes.collection)
					dot += "\n\t" + StringUtil.getDotString(node.name) + " [label=\""+node.name+"\"];";
				
				for each(var link:PhysicalLink in location.links.collection)
				{
					for(var i:int = 0; i < link.interfaces.length; i++)
					{
						for(var j:int = i+1; j < link.interfaces.length; j++)
							dot += "\n\t" + StringUtil.getDotString(link.interfaces.collection[i].owner.name) + " -- " + StringUtil.getDotString(link.interfaces.collection[j].owner.name) + ";";
					}
				}
			}
			
			return dot + "\n}";
		}
	}
}