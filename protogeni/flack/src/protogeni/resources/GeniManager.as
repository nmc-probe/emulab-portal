/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2011 University of Utah and the Flux Group.
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

package protogeni.resources
{
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	
	import protogeni.NetUtil;
	import protogeni.Util;
	import protogeni.XmlUtil;
	import protogeni.communication.Request;
	import protogeni.display.ColorUtil;
	
	/**
	 * Manager within the GENI world
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniManager
	{
		public static const STATUS_UNKOWN:int = 0;
		public static const STATUS_INPROGRESS:int = 1;
		public static const STATUS_VALID:int = 2;
		public static const STATUS_FAILED:int = 3;
		
		public static const TYPE_PROTOGENI:int = 0;
		public static const TYPE_PLANETLAB:int = 1;
		
		public static var processing:int = 0;
		public static var maxProcessing:int = 1;
		
		[Bindable]
		public var Url:String = "";
		
		[Bindable]
		public var Hrn:String = "";
		
		[Bindable]
		public var Urn:IdnUrn = new IdnUrn();
		
		[Bindable]
		public var Version:int;
		
		[Bindable]
		public var outputRspecVersion:Number;
		[Bindable]
		public var inputRspecVersion:Number;
		
		[Bindable]
		public var outputRspecDefaultVersion:Number;
		
		public var inputRspecVersions:Vector.<Number>;
		public var outputRspecVersions:Vector.<Number>;
		
		public var generated:Date;
		public var expires:Date;
		
		[Bindable]
		public var errorMessage:String = "";
		public var errorDescription:String = "";
		
		[Bindable]
		public var Status:int = STATUS_UNKOWN;
		
		public var Rspec:XML = null;
		
		public var supportsIon:Boolean = false;
		public var supportsGpeni:Boolean = false;
		public var supportsDelayNodes:Boolean = false;
		public var supportsSharedNodes:Boolean = true;
		public var supportsExclusiveNodes:Boolean = true;
		
		[Bindable]
		public var Show:Boolean = true;
		
		public var Nodes:PhysicalNodeGroupCollection;
		public var Links:PhysicalLinkGroupCollection = new PhysicalLinkGroupCollection();
		
		public var AllNodes:Vector.<PhysicalNode> = new Vector.<PhysicalNode>();
		[Bindable]
		public var DiskImages:ArrayCollection = new ArrayCollection();
		
		public var colorIdx:int;
		
		public var data:*;
		
		public var isAm:Boolean = false;
		
		public var linksUnadded:int = 0;
		public var nodesUnadded:int = 0;
		
		public function AllNodesAsArray():Array {
			var allNodesArray:Array = new Array();
			for each (var elem:PhysicalNode in AllNodes) {
				allNodesArray.push(elem);
			}
			return allNodesArray;
		}
		public var AllLinks:Vector.<PhysicalLink> = new Vector.<PhysicalLink>();
		public function AllLinksAsArray():Array {
			var allLinksArray:Array = new Array();
			for each (var elem:PhysicalLink in AllLinks) {
				allLinksArray.push(elem);
			}
			return allLinksArray;
		}
		
		// For now set when RSPEC is parsed
		public function get totalNodes():int {
			if(this.AllNodes != null)
				return this.AllNodes.length;
			else
				return 0;
		}
		
		public function get availableNodes():int {
			var count:int = 0;
			if(this.AllNodes != null) {
				for each(var node:PhysicalNode in this.AllNodes) {
					if(node.available)
						count++;
				}
				return count;
			}
			else
				return 0;
		}
		
		public function get unavailableNodes():int {
			var count:int = 0;
			if(this.AllNodes != null) {
				for each(var node:PhysicalNode in this.AllNodes) {
					if(!node.available)
						count++;
				}
				return count;
			}
			else
				return 0;
		}
		
		public function get percentageAvailable():int {
			if(this.AllNodes != null && this.AllNodes.length > 0) {
				return (this.availableNodes * 100) / this.AllNodes.length;
			}
			else
				return 0;
		}
		
		public var rspecProcessor:RspecProcessorInterface;
		
		public var type:int;
		
		public function GeniManager()
		{
			Nodes = new PhysicalNodeGroupCollection(this);
			colorIdx = ColorUtil.getColorIdx();
		}
		
		public function VisitUrl():String
		{
			return NetUtil.tryGetBaseUrl(Url);
		}
		
		public function mightNeedSecurityException():Boolean
		{
			return errorMessage.search("#2048") > -1;
		}
		
		public function getAvailableNodes():Vector.<PhysicalNode>
		{
			var availNodes:Vector.<PhysicalNode> = new Vector.<PhysicalNode>();
			for each(var n:PhysicalNode in AllNodes)
			{
				if(n.available)
					availNodes.push(n);
			}
			return availNodes;
		}
		
		public function getTypes():ArrayList
		{
			var tempNodeTypes:ArrayList = new ArrayList();
			var tmp:Array = [];
			for each(var node:PhysicalNode in this.AllNodes) {
				for each(var nodeType:String in node.hardwareTypes) {
					if(tmp.indexOf(nodeType) == -1)
						tmp.push(nodeType);
				}
			}
			tmp.sort();
			for each(var t:String in tmp)
				tempNodeTypes.addItem(t);
			return tempNodeTypes;
		}
		
		public function clear():void
		{
			clearComponents();
			Rspec = null;
			Status = GeniManager.STATUS_UNKOWN;
			errorMessage = "";
			errorDescription = "";
		}
		
		public function clearComponents():void {
			this.Nodes = new PhysicalNodeGroupCollection(this);
			this.Links = new PhysicalLinkGroupCollection();
			this.nodesUnadded = 0;
			this.linksUnadded = 0;
			this.AllNodes = new Vector.<PhysicalNode>();
			this.AllLinks = new Vector.<PhysicalLink>();
			this.DiskImages = new ArrayCollection();
		}
		
		public function getGraphML():String {
			var graphMl:XML = new XML("<?xml version=\"1.0\" encoding=\"UTF-8\"?><graphml />");
			var graphMlNamespace:Namespace = new Namespace(null, "http://graphml.graphdrawing.org/xmlns");
			graphMl.setNamespace(graphMlNamespace);
			var xsiNamespace:Namespace = XmlUtil.xsiNamespace;
			graphMl.addNamespace(xsiNamespace);
			graphMl.@xsiNamespace::schemaLocation = "http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd";
			graphMl.@id = this.Hrn;
			graphMl.@edgedefault = "undirected";
			
			for each(var node:PhysicalNode in this.AllNodes) {
				var nodeXml:XML = <node />;
				nodeXml.@id = node.id;
				nodeXml.@name = node.name;
				for each(var nodeInterface:PhysicalNodeInterface in node.interfaces.collection) {
					var nodeInterfaceXml:XML = <port />;
					nodeInterfaceXml.@name = nodeInterface.id;
					nodeXml.appendChild(nodeInterfaceXml);
				}
				graphMl.appendChild(nodeXml);
			}
			
			for each(var link:PhysicalLink in this.AllLinks) {
				var hyperedgeXml:XML = <hyperedge />;
				hyperedgeXml.@id = link.id;
				for each(var linkInterface:PhysicalNodeInterface in link.interfaceRefs.collection) {
					var endpointXml:XML = <endpoint />;
					endpointXml.@node = linkInterface.owner.id;
					endpointXml.@port = linkInterface.id;
					hyperedgeXml.appendChild(endpointXml);
				}
				graphMl.appendChild(hyperedgeXml);
			}
			
			return graphMl;
		}
		
		public function getDotGraph():String {
			var dot:String = "graph " + Util.getDotString(Hrn) + " {";
			
			for each(var node:PhysicalNode in this.AllNodes) {
				dot += "\n\t" + Util.getDotString(node.name) + " [label=\""+node.name+"\"];";
			}
			
			for each(var link:PhysicalLink in this.AllLinks) {
				for(var i:int = 0; i < link.interfaceRefs.length; i++) {
					for(var j:int = i+1; j < link.interfaceRefs.length; j++) {
						dot += "\n\t" + Util.getDotString(link.interfaceRefs.collection[i].owner.name) + " -- " + Util.getDotString(link.interfaceRefs.collection[j].owner.name) + ";";
					}
				}
			}
			
			return dot + "\n}";
		}
	}
}