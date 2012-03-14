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
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.virtual.extensions.ClientInfo;
	import com.flack.geni.resources.virtual.extensions.SliceFlackInfo;
	import com.flack.geni.resources.virtual.extensions.slicehistory.SliceHistory;
	import com.flack.geni.resources.virtual.extensions.slicehistory.SliceHistoryItem;
	import com.flack.geni.tasks.groups.slice.ImportSliceTaskGroup;
	import com.flack.geni.tasks.process.GenerateRequestManifestTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.utils.DateUtil;
	
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.DateTimeStyle;
	import flash.globalization.LocaleID;

	/**
	 * Container for slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public class Slice extends IdentifiableObject
	{
		[Bindable]
		public var hrn:String = "";
		public function get Name():String
		{
			if(id != null)
				return id.name;
			else if(hrn != null)
				return hrn;
			else
				return "";
		}
		
		public var creator:GeniUser = null;
		public var authority:GeniAuthority = null;
		public var credential:GeniCredential = null;
		public var flackInfo:SliceFlackInfo = new SliceFlackInfo();
		public var reportedManagers:GeniManagerCollection = new GeniManagerCollection();
		public var description:String = "";
		
		public var slivers:SliverCollection = new SliverCollection();
		public function get RelatedItems():Array
		{
			var results:Array = [this];
			for each(var sliver:Sliver in slivers.collection)
				results.push(sliver);
			return results;
		}
		
		public var nodes:VirtualNodeCollection = new VirtualNodeCollection();
		public var links:VirtualLinkCollection = new VirtualLinkCollection();
		
		public var expires:Date = null;
		public function get EarliestExpires():Date
		{
			if(expires != null)
			{
				if(slivers != null && slivers.length > 0)
				{
					var sliverExpires:Date = slivers.EarliestExpiration;
					if(sliverExpires != null && sliverExpires < expires)
						return sliverExpires;
				}
				return expires;
			}
			return null;
		}
		public function get ExpiresString():String
		{
			var dateFormatter:DateTimeFormatter = new DateTimeFormatter(LocaleID.DEFAULT, DateTimeStyle.SHORT, DateTimeStyle.NONE);
			var result:String = "";
			if(expires != null)
			{
				var sliceExpiresDate:Date = expires;
				if(slivers != null)
				{
					var sliversExpire:Date = slivers.EarliestExpiration;
					if(sliversExpire != null && sliversExpire.time < sliceExpiresDate.time)
					{
						sliceExpiresDate = sliceExpiresDate;
						result = "Sliver expires before slice in\n\t"
							+ DateUtil.getTimeUntil(sliversExpire)
							+ "\n\ton "
							+ dateFormatter.format(sliversExpire)
							+ "\n\n";
					}
				}
				
				result += "Slice expires in\n\t"
					+ DateUtil.getTimeUntil(expires)
					+ "\n\ton "
					+ dateFormatter.format(expires);
			}
			else
				result = "No expiration date yet";
			
			return result;
		}
		
		public function get UnsubmittedChanges():Boolean
		{
			for each(var sliver:Sliver in slivers.collection)
			{
				if(sliver.UnsubmittedChanges)
					return true;
			}
			if(nodes.UnsubmittedChanges)
				return true;
			if(links.UnsubmittedChanges)
				return true;
			return false;
		}
		
		[Bindable]
		public var useInputRspecInfo:RspecVersion = GeniMain.usableRspecVersions.MaxVersion;
		
		// Client extension
		public var clientInfo:ClientInfo = new ClientInfo();
		
		// Flack extension
		public var history:SliceHistory = new SliceHistory();
		
		/**
		 * 
		 * @param id IDN-URN
		 * 
		 */
		public function Slice(id:String = "")
		{
			super(id);
		}
		
		public function pushState():void
		{
			// Don't push an empty state
			if(nodes.length == 0)
				return;
			
			// Remove any redo history
			if(history.backIndex < history.states.length-1)
				history.states.splice(history.backIndex+1, history.states.length - history.backIndex - 1);
			
			var oldHistory:SliceHistory = history;
			
			var getRspec:GenerateRequestManifestTask = new GenerateRequestManifestTask(this, null, false);
			getRspec.start();
			
			oldHistory.states.push(
				new SliceHistoryItem(
					getRspec.resultRspec.document,
					history.stateName
				)
			);
			oldHistory.backIndex = history.states.length-1;
			history = oldHistory;
			history.stateName = "";
			
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLICE,
				this
			);
		}
		
		public function get CanGoBack():Boolean
		{
			return history.backIndex > -1 || nodes.length > 0;
		}
		
		public function get CanGoForward():Boolean
		{
			return history.backIndex < history.states.length-1;
		}
		
		public function backState():String
		{
			// Save the state to return in case user wants to redo
			var oldRspec:String = "";
			if(CanGoBack)
			{
				var saveRspec:GenerateRequestManifestTask = new GenerateRequestManifestTask(this, null, false);
				saveRspec.start();
				
				history.states.splice(history.backIndex+1, 0,
					new SliceHistoryItem(
						saveRspec.resultRspec.document,
						history.stateName
					)
				);
				
				oldRspec = saveRspec.resultRspec.document;
				
				if(history.backIndex > -1)
				{
					var oldHistory:SliceHistory = history;
					var restoreHistoryItem:SliceHistoryItem = history.states.slice(history.backIndex, history.backIndex+1)[0];
					
					var importRspec:ImportSliceTaskGroup = new ImportSliceTaskGroup(this, restoreHistoryItem.rspec, null, true);
					importRspec.start();
					
					// Remove old state which is now the current state
					oldHistory.states.splice(oldHistory.backIndex, 1);
					oldHistory.stateName = restoreHistoryItem.note;
					oldHistory.backIndex--;
					history = oldHistory;
				}
				else
				{
					removeComponents();
					slivers.cleanup();
					for each(var sliver:Sliver in this.slivers.collection)
						sliver.UnsubmittedChanges = true;
				}
			}
			
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLICE,
				this
			);
			
			return oldRspec;
		}
		
		public function forwardState():String
		{
			if(history.backIndex < history.states.length-1)
			{
				var oldHistory:SliceHistory = history;
				var restoreHistoryItem:SliceHistoryItem = history.states.slice(history.backIndex+1, history.backIndex+2)[0];
				
				// Save the state to return in case user wants to undo
				var saveRspec:GenerateRequestManifestTask = new GenerateRequestManifestTask(this, null, false);
				saveRspec.start();
				
				// Save current state into history for undo
				oldHistory.states.splice(history.backIndex+1, 0,
					new SliceHistoryItem(
						saveRspec.resultRspec.document,
						history.stateName
					)
				);
				
				var importRspec:ImportSliceTaskGroup = new ImportSliceTaskGroup(this, restoreHistoryItem.rspec, null, true);
				importRspec.start();
				
				// Remove old state which is now the current state
				oldHistory.states.splice(oldHistory.backIndex+2, 1);
				oldHistory.stateName = restoreHistoryItem.note;
				oldHistory.backIndex++;
				history = oldHistory;
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_SLICE,
					this
				);
				
				return saveRspec.resultRspec.document
			}
			else
				return "";
		}
		
		public function resetStatus():void
		{
			for each(var statusSliver:Sliver in slivers.collection)
			{
				if(statusSliver.sliverIdToStatus[statusSliver.id.full] != null)
					statusSliver.status = statusSliver.sliverIdToStatus[statusSliver.id.full];
			}
			for each(var statusNode:VirtualNode in nodes.collection)
			{
				var nodeSliver:Sliver = slivers.getByManager(statusNode.manager);
				if(nodeSliver != null && nodeSliver.sliverIdToStatus[statusNode.id.full] != null)
					statusNode.status = nodeSliver.sliverIdToStatus[statusNode.id.full];
				else
					statusNode.status = "";
			}
			for each(var statusLink:VirtualLink in links.collection)
			{
				var linkSlivers:SliverCollection = slivers.getByManagers(statusLink.interfaceRefs.Interfaces.Managers);
				if(linkSlivers.length > 0 && linkSlivers.collection[0].sliverIdToStatus[statusLink.id.full] != null)
					statusLink.status = linkSlivers.collection[0].sliverIdToStatus[statusLink.id.full];
				else
					statusLink.status = "";
			}
		}
		
		public function getBySliverId(sliverId:String):*
		{
			var obj:* = nodes.getBySliverId(sliverId);
			if(obj != null) return obj;
			obj = nodes.getInterfaceBySliverId(sliverId);
			if(obj != null) return obj;
			obj = links.getBySliverId(sliverId);
			if(obj != null) return obj;
			if(id.full == sliverId) return this;
			obj = slivers.getBySliverId(sliverId);
			if(obj != null) return obj;
			return null;
		}
		
		public function getByClientId(clientId:String):*
		{
			var obj:* = nodes.getByClientId(clientId);
			if(obj != null) return obj;
			obj = nodes.getInterfaceByClientId(clientId);
			if(obj != null) return obj;
			obj = links.getByClientId(clientId);
			if(obj != null) return obj;
			return null;
		}
		
		public function isIdUnique(obj:*, testId:String):Boolean
		{
			var result:* = nodes.getByClientId(testId);
			if(result != null && result != obj)
				return false;
			result = links.getByClientId(testId);
			if(result != null && result != obj)
				return false;
			return true;
		}
		
		public function getUniqueId(obj:*, base:String, start:int = 0):String
		{
			var start:int = start;
			var highest:int = start;
			while(!links.isIdUnique(obj, base + highest))
				highest++;
			while(!nodes.isIdUnique(obj, base + highest))
				highest++;
			if(id.full == base + highest)
				highest++;
			if(highest > start)
				return getUniqueId(obj, base, highest);
			else
				return base + highest;
		}
		
		public function get State():String
		{
			if(!slivers.AllocatedAnyResources)
				return "";
			
			var state:String = "";
			var usingManagers:GeniManagerCollection = nodes.Managers;
			for each(var manager:GeniManager in usingManagers.collection)
			{
				var sliver:Sliver = slivers.getByManager(manager);
				if(sliver == null || !sliver.Created)
					return Sliver.STATE_MIXED;
				else
				{
					if(state.length == 0) state = sliver.state;
					if(sliver.state != state)
						state = Sliver.STATE_MIXED;
				}
			}
			return state;
		}
		
		public function get Status():String
		{
			if(!slivers.AllocatedAnyResources || UnsubmittedChanges)
				return "";
			
			var status:String = "";
			var usingManagers:GeniManagerCollection = nodes.Managers;
			for each(var manager:GeniManager in usingManagers.collection)
			{
				var sliver:Sliver = slivers.getByManager(manager);
				if(sliver == null || !sliver.Created)
					return Sliver.STATUS_MIXED;
				else
				{
					if(status.length == 0)
					{
						if(sliver.status.length == 0)
							return Sliver.STATE_MIXED;
						status = sliver.status;
					}
					if(sliver.status != status)
						status = Sliver.STATUS_MIXED;
				}
			}
			return status;
		}
		
		public function get StatusesFinalized():Boolean
		{
			var usingManagers:GeniManagerCollection = nodes.Managers;
			for each(var manager:GeniManager in usingManagers.collection)
			{
				var sliver:Sliver = slivers.getByManager(manager);
				if(sliver == null || !sliver.Created)
					return false;
				else
				{
					if(!sliver.StatusFinalized)
						return false;
				}
			}
			return true;
		}
		
		public function clearStatus():void
		{
			for each(var sliver:Sliver in slivers.collection)
				sliver.clearStatus();
		}
		
		/**
		 * Removes manifests/sliver_ids from components and clears states.
		 * 
		 * Slivers still have manifests to indicate they were created.
		 * 
		 */
		public function markStaged():void
		{
			for each(var sliver:Sliver in slivers.collection)
				sliver.markStaged();
				
			for each(var virtualNode:VirtualNode in nodes.collection)
			{
				virtualNode.clearState();
				virtualNode.id = new IdnUrn();
				virtualNode.manifest = "";
			}
			for each(var virtualLink:VirtualLink in links.collection)
			{
				virtualLink.clearState();
				virtualLink.id = new IdnUrn();
				virtualLink.manifest = "";
			}
		}
		
		/**
		 * Removes everything from the slice
		 * 
		 */
		public function removeAll():void
		{
			clientInfo = new ClientInfo();
			history = new SliceHistory();
			
			slivers = new SliverCollection();
			
			reportedManagers = new GeniManagerCollection();
			
			removeComponents();
		}
		
		public function removeComponents():void
		{
			nodes = new VirtualNodeCollection();
			links = new VirtualLinkCollection();
		}
		
		override public function toString():String
		{
			var result:String = "[Slice ID="+id.full+"]\n";
			for each(var sliver:Sliver in slivers.collection)
				result += "\t"+sliver.toString() + "\n";
			for each(var node:VirtualNode in nodes.collection)
				result += "\t"+node.toString() + "\n";
			for each(var link:VirtualLink in links.collection)
				result += "\t"+link.toString() + "\n";
			result += "\t[History States=\""+history.states.length+"\" /]\n";
			return result+"[/Slice]";
		}
	}
}