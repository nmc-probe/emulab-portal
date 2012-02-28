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

package com.flack.geni.resources.virtual
{
	import com.flack.geni.resources.Extensions;
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.docs.RspecVersion;
	
	import flash.utils.Dictionary;

	/**
	 * Holds resources for a slice at one manager
	 * 
	 * @author mstrum
	 * 
	 */
	public class Sliver extends IdentifiableObject
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
		public static const STATUS_STOPPED:String = "stopped";
		
		[Bindable]
		public var slice:Slice;
		[Bindable]
		public var manager:GeniManager;
		
		public var credential:GeniCredential;
		public var expires:Date = null;
		
		[Bindable]
		public var forceUseInputRspecInfo:RspecVersion;
		
		public var state:String = "";
		public var status:String = "";
		public function get StatusFinalized():Boolean
		{
			return status == STATUS_READY
				|| status == STATUS_FAILED
				|| status == STATUS_UNKNOWN
				|| status == STATUS_STOPPED;
		}
		public function clearStatus():void
		{
			state = "";
			status = "";
			var clearNodes:VirtualNodeCollection = slice.nodes.getByManager(manager);
			for each(var node:VirtualNode in clearNodes.collection)
				node.clearState();
			var clearLinks:VirtualLinkCollection = slice.links.getConnectedToManager(manager);
			for each(var link:VirtualLink in clearLinks.collection)
				link.clearState();
		}
		
		public var sliverIdToStatus:Dictionary = new Dictionary();
		
		public var ticket:String = "";
		public var manifest:Rspec = null;
		
		private var unsubmittedChanges:Boolean = true;
		public function get UnsubmittedChanges():Boolean
		{
			if(unsubmittedChanges)
				return true;
			if(slice.nodes.getByManager(manager).UnsubmittedChanges)
				return true;
			if(slice.links.getConnectedToManager(manager).UnsubmittedChanges)
				return true;
			return false;
		}
		public function set UnsubmittedChanges(value:Boolean):void
		{
			unsubmittedChanges = value;
		}
		
		public var extensions:Extensions = new Extensions();
		
		public function get Created():Boolean
		{
			return manifest != null;
		}
		
		public function get Nodes():VirtualNodeCollection
		{
			return slice.nodes.getByManager(manager);
		}
		
		public function get Links():VirtualLinkCollection
		{
			return slice.links.getConnectedToManager(manager);
		}
		
		/**
		 * 
		 * @param owner Slice for the sliver
		 * @param newManager Manager where the sliver lies
		 * 
		 */
		public function Sliver(owner:Slice,
							   newManager:GeniManager = null)
		{
			super();
			slice = owner;
			manager = newManager;
		}
		
		/**
		 * Removes status and manifests from everything from this sliver, BUT not the sliver's manifest
		 * 
		 */
		public function markStaged():void
		{
			// XXX unsubmittedChanges?
			
			state = "";
			status = "";
			if(slice != null)
			{
				for each(var virtualNode:VirtualNode in slice.nodes.collection)
				{
					if(virtualNode.manager == manager)
						virtualNode.markStaged();
				}
				for each(var virtualLink:VirtualLink in slice.links.collection)
				{
					for each(var linkManager:GeniManager in virtualLink.interfaceRefs.Interfaces.Managers.collection)
					{
						if(linkManager == manager)
						{
							virtualLink.markStaged();
							break;
						}
					}
					
				}
			}
		}
		
		public function removeFromSlice():void
		{
			slice.reportedManagers.remove(manager);
			// Remove the nodes, no links will be left
			for(var i:int = 0; i < slice.nodes.length; i++)
			{
				var node:VirtualNode = slice.nodes.collection[i];
				if(node.manager == manager)
				{
					node.removeFromSlice();
					i--;
				}
			}
			// unsubmittedChanges = true;
			slice.slivers.remove(this);
		}
		
		override public function toString():String
		{
			return "[Sliver ID="+id.full+", Manager="+manager.id.full+", HasManifest="+Created+", Status="+status+", State="+state+"]";
		}
	}
}