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

package com.flack.geni.resources.sites
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.SliverTypeCollection;
	import com.flack.geni.resources.physical.PhysicalLink;
	import com.flack.geni.resources.physical.PhysicalLinkCollection;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.physical.PhysicalNodeCollection;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.sites.FlackManager;

	/**
	 * Collection of managers
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GeniManagerCollection
	{
		public var collection:Vector.<GeniManager>;
		public function GeniManagerCollection()
		{
			collection = new Vector.<GeniManager>();
		}
		
		public function add(manager:GeniManager):void
		{
			collection.push(manager);
		}
		
		public function remove(manager:GeniManager):void
		{
			var idx:int = collection.indexOf(manager);
			if(idx > -1)
				collection.splice(idx, 1);
		}
		
		public function contains(manager:GeniManager):Boolean
		{
			return collection.indexOf(manager) > -1;
		}
		
		public function get length():int
		{
			return collection.length;
		}
		
		/**
		 * 
		 * @return New instance of the same collection
		 * 
		 */
		public function get Clone():GeniManagerCollection
		{
			var clone:GeniManagerCollection = new GeniManagerCollection();
			for each(var manager:GeniManager in collection)
				clone.add(manager);
			return clone;
		}
		
		/**
		 * 
		 * @return Managers which have reported resources
		 * 
		 */
		public function get Valid():GeniManagerCollection
		{
			var validManagers:GeniManagerCollection = new GeniManagerCollection();
			for each(var manager:GeniManager in collection)
			{
				if(manager.Status == FlackManager.STATUS_VALID)
					validManagers.add(manager);
			}
			return validManagers;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Manager matching the ID
		 * 
		 */
		public function getById(id:String):GeniManager
		{
			var idnUrn:IdnUrn = new IdnUrn(id);
			for each(var gm:GeniManager in collection)
			{
				if(gm.id.authority == idnUrn.authority)
					return gm;
			}
			return null;
		}
		
		/**
		 * 
		 * @param id IDN-URN
		 * @return Component matching the id
		 * 
		 */
		public function getComponentById(id:String):*
		{
			for each(var gm:GeniManager in collection)
			{
				var component:* = gm.getById(id);
				if(component != null)
					return component;
			}
			return null;
		}
		
		/**
		 * 
		 * @param hrn Human-readable name
		 * @return Manager matching the hrn
		 * 
		 */
		public function getByHrn(hrn:String):GeniManager
		{
			for each(var manager:GeniManager in collection)
			{
				if(manager.hrn == hrn)
					return manager;
			}
			return null;
		}
		
		/**
		 * 
		 * @return All nodes
		 * 
		 */
		public function get Nodes():PhysicalNodeCollection
		{
			var results:PhysicalNodeCollection = new PhysicalNodeCollection();
			for each(var manager:GeniManager in collection)
			{
				for each(var node:PhysicalNode in manager.nodes.collection)
					results.add(node);
			}
			return results; 
		}
		
		/**
		 * 
		 * @return All links
		 * 
		 */
		public function get Links():PhysicalLinkCollection
		{
			var results:PhysicalLinkCollection = new PhysicalLinkCollection();
			for each(var manager:GeniManager in collection)
			{
				for each(var link:PhysicalLink in manager.links.collection)
					results.add(link);
			}
			return results; 
		}
		
		/**
		 * 
		 * @return Maximum RSPEC supported by all of the managers
		 * 
		 */
		public function get MaximumRspecVersion():Number
		{
			var max:Number = GeniMain.usableRspecVersions.MaxVersion.version;
			for each(var manager:GeniManager in collection)
			{
				if(manager.inputRspecVersion.version < max)
					max = manager.inputRspecVersion.version;
			}
			return max; 
		}
		
		/**
		 * 
		 * @return List of link types which are usable within the given managers
		 * 
		 */
		public function get CommonLinkTypes():SupportedLinkTypeCollection
		{
			var supportedTypes:SupportedLinkTypeCollection = new SupportedLinkTypeCollection();
			if(collection.length > 0)
			{
				for each(var initialType:SupportedLinkType in collection[0].supportedLinkTypes.collection)
					supportedTypes.add(initialType);
			}
			var i:int = 0;
			var supportedType:SupportedLinkType = null;
			for each(var manager:GeniManager in collection)
			{
				for(i = 0; i < supportedTypes.length; i++)
				{
					supportedType = supportedTypes.collection[i];
					if(manager.supportedLinkTypes.getByName(supportedType.name) == null)
					{
						supportedTypes.remove(supportedType);
						i--;
					}
				}
			}
			for(i = 0; i < supportedTypes.length; i++)
			{
				supportedType = supportedTypes.collection[i];
				if((!supportedType.supportsManyManagers && length > 1)
					|| (!supportedType.supportsSameManager && length == 1))
				{
					supportedTypes.remove(supportedType);
					i--;
				}
			}
			return supportedTypes;
		}
		
		/**
		 * 
		 * @return List of sliver types available at all of the managers
		 * 
		 */
		public function get CommonSliverTypes():SupportedSliverTypeCollection
		{
			var supportedTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
			if(collection.length > 0)
			{
				for each(var initialType:SupportedSliverType in collection[0].supportedSliverTypes.collection)
					supportedTypes.add(initialType);
			}
			for each(var manager:GeniManager in collection)
			{
				for(var i:int = 0; i < supportedTypes.length; i++)
				{
					var supportedType:SupportedSliverType = supportedTypes.collection[i];
					if(manager.supportedSliverTypes.getByName(supportedType.type.name) == null)
					{
						supportedTypes.remove(supportedType);
						i--;
					}
				}
			}
			return supportedTypes;
		}
		
		public function get SupportedSliverTypes():SupportedSliverTypeCollection
		{
			var supportedTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
			for each(var manager:GeniManager in collection)
			{
				for each(var supportedType:SupportedSliverType in manager.supportedSliverTypes.collection)
				{
					if(supportedTypes.getByName(supportedType.type.name) == null)
						supportedTypes.add(supportedType);
				}
			}
			return supportedTypes;
		}
	}
}