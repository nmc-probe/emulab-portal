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
	import protogeni.Util;
	
	public final class SliverCollection
	{
		public var collection:Vector.<Sliver>;
		public function SliverCollection()
		{
			this.collection = new Vector.<Sliver>();
		}
		
		public function add(s:Sliver):void {
			this.collection.push(s);
		}
		
		public function addToBeginning(s:Sliver):void {
			this.collection.unshift(s);
		}
		
		public function remove(s:Sliver):void
		{
			var idx:int = this.collection.indexOf(s);
			if(idx > -1)
				this.collection.splice(idx, 1);
		}
		
		public function contains(s:Sliver):Boolean
		{
			return this.collection.indexOf(s) > -1;
		}
		
		public function get length():int{
			return this.collection.length;
		}
		
		public function isIdUnique(o:*, id:String):Boolean {
			if(!this.VirtualLinks.isIdUnique(o, id))
				return false;
			if(!this.VirtualNodes.isIdUnique(o, id))
				return false;
			return true;
		}
		
		public function addIfNotExisting(s:Sliver):void
		{
			if(s == null)
				return;
			for each(var sliver:Sliver in this.collection)
			{
 				if(sliver.manager == s.manager)
					return;
			}
			this.collection.push(s);
		}
		
		public function getByUrn(urn:String):Sliver
		{
			for each(var sliver:Sliver in this.collection)
			{
				if(sliver.urn.full == urn)
					return sliver;
			}
			return null;
		}
		
		public function getByManager(gm:GeniManager):Sliver
		{
			for each(var sliver:Sliver in this.collection)
			{
				if(sliver.manager == gm)
					return sliver;
			}
			return null;
		}
		
		public function getNodeWithClientId(id:String):VirtualNode
		{
			for each(var s:Sliver in this.collection)
			{
				var vn:VirtualNode = s.nodes.getByClientId(id);
				if(vn != null)
					return vn;
			}
			return null;
		}
		
		public function getNodeWithSliverId(id:String):VirtualNode
		{
			for each(var s:Sliver in this.collection)
			{
				var vn:VirtualNode = s.nodes.getBySliverId(id);
				if(vn != null)
					return vn;
			}
			return null;
		}
		
		public function getInterfaceWithId(id:String):VirtualInterface
		{
			for each(var s:Sliver in this.collection)
			{
				var vi:VirtualInterface = s.nodes.getByInterfaceId(id);
				if(vi != null)
					return vi;
			}
			return null;
		}
		
		public function getLinkWithClientId(id:String):VirtualLink
		{
			for each(var s:Sliver in this.collection)
			{
				var vl:VirtualLink = s.links.getByClientId(id);
				if(vl != null)
					return vl;
			}
			return null;
		}
		
		public function getLinkWithSliverId(id:String):VirtualLink
		{
			for each(var s:Sliver in this.collection)
			{
				var vl:VirtualLink = s.links.getBySliverId(id);
				if(vl != null)
					return vl;
			}
			return null;
		}
		
		public function getUniqueVirtualLinkId(l:VirtualLink = null):String
		{
			var highest:int = 0;
			for each(var s:Sliver in this.collection)
			{
				for each(var l:VirtualLink in s.links.collection)
				{
					try
					{
						if(l.clientId.substr(0,5) == "link-")
						{
							var testHighest:int = parseInt(l.clientId.substring(5));
							if(testHighest >= highest)
								highest = testHighest+1;
						}
					} catch(e:Error) { }
				}
			}
			return "link-" + highest;
		}
		
		public function getUniqueVirtualNodeId(n:VirtualNode = null):String
		{
			var newId:String;
			if(n == null)
				newId = "node-";
			else
			{
				if(n.isDelayNode)
					newId = "bridge-";
				else if(n.Exclusive)
					newId = "exclusive-";
				else
					newId = "shared-";
			}
			
			var highest:int = 0;
			for each(var s:Sliver in this.collection)
			{
				for each(var testNode:VirtualNode in s.nodes.collection)
				{
					try
					{
						if(testNode.clientId.indexOf(newId) == 0) {
							var testHighest:int = parseInt(testNode.clientId.substring(testNode.clientId.lastIndexOf("-")+1));
							if(testHighest >= highest)
								highest = testHighest+1;
						}
					} catch(e:Error) {}
				}
			}
			
			return newId + highest;
		}
		
		public function getUniqueVirtualInterfaceId():String
		{
			var highest:int = 0;
			for each(var s:Sliver in this.collection)
			{
				for each(var l:VirtualLink in s.links.collection)
				{
					for each(var i:VirtualInterface in l.interfaces.collection)
					{
						try
						{
							if(i.id.substr(0,10) == "interface-")
							{
								var testHighest:int = parseInt(i.id.substring(10));
								if(testHighest >= highest)
									highest = testHighest+1;
							}
						} catch(e:Error) { }
					}
					
				}
			}
			return "interface-" + highest;
		}
		
		public function get VirtualNodes():VirtualNodeCollection
		{
			var nodes:VirtualNodeCollection = new VirtualNodeCollection();
			for each(var s:Sliver in this.collection)
			{
				for each(var n:VirtualNode in s.nodes.collection)
				{
					if(n.manager == s.manager)
						nodes.add(n);
				}
				
			}
			return nodes;
		}
		
		public function get PhysicalNodes():Vector.<PhysicalNode>
		{
			var nodes:Vector.<PhysicalNode> = new Vector.<PhysicalNode>();
			for each(var s:Sliver in this.collection)
			{
				for each(var n:VirtualNode in s.nodes.collection)
				{
					if(nodes.indexOf(n) == -1 && n.physicalNode != null)
						nodes.push(n.physicalNode);
				}
				
			}
			return nodes;
		}
		
		public function get VirtualLinks():VirtualLinkCollection
		{
			var links:VirtualLinkCollection = new VirtualLinkCollection();
			for each(var s:Sliver in this.collection)
			{
				for each(var l:VirtualLink in s.links.collection)
				{
					if(!links.contains(l))
						links.add(l);
				}
				
			}
			return links;
		}
		
		public function get StatusFinalized():Boolean {
			for each(var s:Sliver in this.collection)
			{
				if(!s.StatusFinalized)
					return false;
				
			}
			return true;
		}
		
		public function get Combined():Sliver
		{
			if(this.collection.length == 0)
				return null;
			var fakeManager:ProtogeniComponentManager = new ProtogeniComponentManager();
			if(this.collection.length > 0)
				fakeManager.inputRspecVersion = this.collection[0].slice.useInputRspecVersion;
			else
				fakeManager.inputRspecVersion = Util.defaultRspecVersion;
			fakeManager.Hrn = "Combined";
			var newSliver:Sliver = new Sliver(null, fakeManager);
			for each(var sliver:Sliver in this.collection) {
				for each(var ns:Namespace in sliver.extensionNamespaces) {
					if(newSliver.extensionNamespaces.indexOf(ns) == -1)
						newSliver.extensionNamespaces.push(ns);
				}
				if(newSliver.slice == null)
					newSliver.slice = sliver.slice;
				for each(var node:VirtualNode in sliver.nodes.collection) {
					if(!newSliver.nodes.contains(node))
						newSliver.nodes.add(node);
				}
				for each(var link:VirtualLink in sliver.links.collection) {
					if(!newSliver.links.contains(link))
						newSliver.links.add(link);
				}
			}
			return newSliver;
		}
		
		public function get Expires():Date {
			var d:Date = null;
			for each(var sliver:Sliver in this.collection)
			{
				if(d == null || sliver.expires < d)
					d = sliver.expires;
			}
			return d;
		}
		
		public function get Status():String {
			var status:String = "";
			for each(var sliver:Sliver in this.collection) {
				if(status.length == 0) status = sliver.status;
				if(sliver.status.length > 0 && (sliver.status != Sliver.STATUS_READY && sliver.status != Sliver.STATUS_FAILED))
					return Sliver.STATUS_CHANGING;
				if(sliver.status != status)
					status = Sliver.STATUS_MIXED;
			}
			return status;
		}
		
		public function get Changing():Boolean {
			for each(var sliver:Sliver in this.collection) {
				if(sliver.changing)
					return true;
			}
			return false;
		}
		
		public function get AllocatedAnyResources():Boolean {
			for each(var sliver:Sliver in this.collection) {
				if(sliver.Created)
					return true;
			}
			return false;
		}
		
		public function get HasAnyStatusInfo():Boolean {
			for each(var sliver:Sliver in this.collection) {
				if(sliver.message.length > 0 || sliver.changing || sliver.status.length > 0 || sliver.Created)
					return true;
			}
			return false;
		}
	}
}