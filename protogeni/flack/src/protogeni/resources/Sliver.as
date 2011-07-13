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
	/**
	 * Holds resources for a slice at one manager
	 * 
	 * @author mstrum
	 * 
	 */
	public class Sliver
	{
		public static const STATE_STARTED:String = "started";
		public static const STATE_STOPPED:String = "stopped";
		public static const STATE_MIXED:String = "mixed";
		public static const STATE_NA:String = "N/A";
		
		public static const STATUS_CHANGING:String = "changing";
		public static const STATUS_READY:String = "ready";
		public static const STATUS_NOTREADY:String = "notready";
		public static const STATUS_FAILED:String = "failed";
		public static const STATUS_UNKNOWN:String = "unknown";
		public static const STATUS_MIXED:String = "mixed";
		public static const STATUS_NA:String = "N/A";
		
		[Bindable]
		public var urn:IdnUrn = new IdnUrn();
		
		[Bindable]
		public var slice:Slice;
		public var manager:GeniManager;
		
		public var credential:String = "";
		public var expires:Date = null;
		
		public var state:String = "";
		public var status:String = "";
		
		public var ticket:String = "";
		public var request:XML = null;
		public var manifest:XML = null;
		public function get Created():Boolean {
			return manifest != null;
		}
		
		public var nodes:VirtualNodeCollection = new VirtualNodeCollection();
		public var links:VirtualLinkCollection = new VirtualLinkCollection();
		
		public var extensionNamespaces:Vector.<Namespace> = new Vector.<Namespace>();
		
		public var processed:Boolean = false;
		public var changing:Boolean = false;
		public var message:String = "Nothing done yet";
		
		public function Sliver(owner:Slice,
							   newManager:GeniManager = null)
		{
			this.slice = owner;
			this.manager = newManager;
		}
		
		public function copyStatusFrom(sliver:Sliver):void {
			this.status = sliver.status;
			this.state = sliver.state;
			this.changing = sliver.changing;
			this.message = sliver.message;
			for each(var copyNode:VirtualNode in sliver.nodes.collection) {
				var myNode:VirtualNode = this.nodes.getByClientId(copyNode.clientId);
				if(myNode != null) {
					myNode.status = copyNode.status;
					myNode.state = copyNode.state;
					myNode.error = copyNode.error;
				}
			}
			for each(var copyLink:VirtualLink in sliver.links.collection) {
				var myLink:VirtualLink = this.links.getByClientId(copyLink.clientId);
				if(myLink != null) {
					myLink.status = copyLink.status;
					myLink.state = copyLink.state;
					myLink.error = copyLink.error;
				}
			}
		}
		
		public function get StatusFinalized():Boolean {
			return status == STATUS_READY
				|| status == STATUS_FAILED
				|| status == STATUS_UNKNOWN;
		}
		
		public function getBySliverId(id:String):VirtualComponent {
			var obj:* = this.nodes.getBySliverId(id);
			if(obj != null)
				return obj;
			return this.links.getBySliverId(id);
		}
		
		public function clearResources():void
		{
			this.nodes = new VirtualNodeCollection();
			this.links = new VirtualLinkCollection();
			this.extensionNamespaces = new Vector.<Namespace>();
		}
		
		public function clearState():void
		{
			this.state = "";
			this.status = "";
			this.processed = false;
			this.changing = false;
		}
		
		public function clearAll():void
		{
			clearResources();
			clearState();
			this.request = null;
			this.ticket = "";
			this.manifest = null;
		}
		
		public function removeOutsideReferences():void
		{
			for each(var node:VirtualNode in this.nodes.collection)
			{
				if(node.physicalNode != null
					&& node.physicalNode.virtualNodes.contains(node))
					node.physicalNode.virtualNodes.remove(node);
			}
		}
		
		public function parseManifest(newManifest:XML = null):void {
			if(newManifest != null)
				this.manifest = newManifest;
			this.manager.rspecProcessor.processSliverRspec(this, this.manifest);
		}
		
		public function parseRspec(newRspec:XML):void {
			this.manager.rspecProcessor.processSliverRspec(this, newRspec);
		}
		
		public function getRequestRspec(removeNonexplicitBinding:Boolean):XML
		{
			return this.manager.rspecProcessor.generateSliverRspec(this, removeNonexplicitBinding, slice.useInputRspecVersion);
		}
	}
}