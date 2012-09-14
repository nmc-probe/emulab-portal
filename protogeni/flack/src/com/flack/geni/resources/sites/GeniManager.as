/*
 * Copyright (c) 2008-2012 University of Utah and the Flux Group.
 * 
 * {{{GENIPUBLIC-LICENSE
 * 
 * GENI Public License
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and/or hardware specification (the "Work") to
 * deal in the Work without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Work, and to permit persons to whom the Work
 * is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Work.
 * 
 * THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
 * IN THE WORK.
 * 
 * }}}
 */

package com.flack.geni.resources.sites
{
	import com.flack.geni.resources.SliverTypeCollection;
	import com.flack.geni.resources.physical.PhysicalLink;
	import com.flack.geni.resources.physical.PhysicalLinkCollection;
	import com.flack.geni.resources.physical.PhysicalLocationCollection;
	import com.flack.geni.resources.physical.PhysicalNode;
	import com.flack.geni.resources.physical.PhysicalNodeCollection;
	import com.flack.shared.resources.docs.RspecVersion;
	import com.flack.shared.resources.docs.RspecVersionCollection;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.resources.sites.FlackManager;
	
	/**
	 * Manager within the GENI world
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniManager extends FlackManager
	{
		public static const ALLOCATE_SINGLE:String = "geni_single";
		public static const ALLOCATE_DISJOINT:String = "geni_disjoint";
		public static const ALLOCATE_MANY:String = "geni_many";
				
		// Advertised Resources
		[Bindable]
		public var nodes:PhysicalNodeCollection;
		[Bindable]
		public var links:PhysicalLinkCollection;
		
		// Support Information
		public var inputRspecVersions:RspecVersionCollection = new RspecVersionCollection();
		[Bindable]
		public var inputRspecVersion:RspecVersion = null;
		
		public var outputRspecVersions:RspecVersionCollection = new RspecVersionCollection();
		[Bindable]
		public var outputRspecVersion:RspecVersion = null;
		
		public var supportedSliverTypes:SupportedSliverTypeCollection = new SupportedSliverTypeCollection();
		public var supportedLinkTypes:SupportedLinkTypeCollection = new SupportedLinkTypeCollection();
		public function get SupportsLinks():Boolean
		{
			return supportedLinkTypes.length > 0;
		}
		
		public var locations:PhysicalLocationCollection;
		
		public var sharedVlans:Vector.<String> = null;
		
		// Added for V3
		public var singleAllocation:Boolean = false;
		public var allocate:String = ALLOCATE_SINGLE;
		
		/**
		 * 
		 * @param newType Type
		 * @param newApi API type
		 * @param newId IDN-URN
		 * @param newHrn Human-readable name
		 * 
		 */
		public function GeniManager(newType:int = TYPE_OTHER,
									newApi:int = ApiDetails.API_GENIAM,
									newId:String = "",
									newHrn:String = "")
		{
			super(
				newType,
				newApi,
				newId,
				newHrn
			);
			
			resetComponents();
		}
		
		/**
		 * Clears components, the advertisement, status, and error details
		 * 
		 */
		override public function clear():void
		{
			resetComponents();
			super.clear();
		}
		
		/**
		 * Clears nodes, links, sliver types, and locations
		 * 
		 */
		public function resetComponents():void
		{
			nodes = new PhysicalNodeCollection();
			links = new PhysicalLinkCollection();
			//supportedSliverTypes = new SupportedSliverTypeCollection();
			//supportedLinkTypes = new SupportedLinkTypeCollection();
			locations = new PhysicalLocationCollection();
		}
		
		/**
		 * Sets the API type to use. This can be overriden to, for example,
		 * set the URL based on the api type.
		 * 
		 * @param type Details for the API to use.
		 * 
		 */
		public function setApi(details:ApiDetails):void
		{
			api = details;
			if(details.url.length == 0)
				api.url = url;
		}
		
		/**
		 * 
		 * @param findId Component ID
		 * @return Component matching the ID
		 * 
		 */
		public function getById(findId:String):*
		{
			var component:* = nodes.getById(findId);
			if(component != null)
				return component;
			return nodes.getInterfaceById(findId);
		}
		
		override public function toString():String
		{
			var result:String = "[GeniManager ID=" + id.full
				+ ", Url=" + url
				+ ", Hrn=" + hrn
				+ ", Type=" + type
				+ ", Api=" + api.type
				+ ", Status=" + Status + "]\n";
			if(nodes.length > 0)
			{
				result += "\t[Nodes]\n";
				for each(var node:PhysicalNode in nodes.collection)
					result += node.toString();
				result += "\t[/Nodes]\n";
			}
			if(links.length > 0)
			{
				result += "\t[Links]\n";
				for each(var link:PhysicalLink in links.collection)
					result += link.toString();
				result += "\t[/Links]\n";
			}
			return result += "[/GeniManager]";
		}
	}
}