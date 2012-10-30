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
			return manifest != null && manifest.length > 0;
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