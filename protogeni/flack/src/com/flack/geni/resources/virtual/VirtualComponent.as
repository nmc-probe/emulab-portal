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
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.IdnUrn;

	/**
	 * Base for nodes and links
	 * 
	 * @author mstrum
	 * 
	 */
	public class VirtualComponent extends IdentifiableObject
	{
		public static const STATUS_CHANGING:String = "changing";
		public static const STATUS_READY:String = "ready";
		public static const STATUS_NOTREADY:String = "notready";
		public static const STATUS_FAILED:String = "failed";
		public static const STATUS_UNKNOWN:String = "unknown";
		public static const STATUS_STOPPED:String = "stopped";
		
		[Bindable]
		public var clientId:String;
		
		public var manifest:String = "";
		public function get Created():Boolean
		{
			return manifest != null;
		}
		public var unsubmittedChanges:Boolean = true;
		
		[Bindable]
		public var slice:Slice;
		
		[Bindable]
		public var error:String = "";
		[Bindable]
		public var state:String = "N/A";
		[Bindable]
		public var status:String = "N/A";
		public function clearState():void
		{
			error = "";
			state = "";
			status = "";
		}
		
		public function markStaged():void
		{
			clearState();
			manifest = "";
			unsubmittedChanges = true;
			id = new IdnUrn();
		}
		
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param newSlice Slice where the component will be located in
		 * @param newClientId Client ID
		 * @param newSliverId Sliver ID, if already created
		 * 
		 */
		public function VirtualComponent(newSlice:Slice,
										 newClientId:String = "",
										 newSliverId:String = "")
		{
			super(newSliverId);
			slice = newSlice;
			clientId = newClientId;
		}
		
		override public function toString():String
		{
			return "[VirtualComponent "+StringProperties+"]";
		}
		
		public function get StringProperties():String
		{
			return "SliverID="+id.full+",\n\t\tState="+state+",\n\t\tStatus="+status+",\n\t\tError="+error+",\n\t\tHasManifest="+Created;
		}
	}
}