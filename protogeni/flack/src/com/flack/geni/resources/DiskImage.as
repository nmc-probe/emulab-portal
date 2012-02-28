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

package com.flack.geni.resources
{
	import com.flack.shared.resources.IdentifiableObject;
	import com.flack.shared.resources.IdnUrn;

	/**
	 * Disk image used for a resource
	 * 
	 * @author mstrum
	 * 
	 */
	public class DiskImage extends IdentifiableObject
	{
		/**
		 * 
		 * @param newId Full IDN-URN string
		 * @param newOs OS description
		 * @param newVersion Version description
		 * @param newDescription General description
		 * @param newIsDefault Is this the default image?
		 * 
		 */
		public function DiskImage(newId:String = "",
								  newOs:String = "",
								  newVersion:String = "",
								  newDescription:String = "",
								  newIsDefault:Boolean = false)
		{
			super(newId);
			if(id.full.length > 0)
				id = IdnUrn.makeFrom(id.authority, id.type, id.name.replace(":", "//"));
			os = newOs;
			version = newVersion;
			description = newDescription;
			isDefault = newIsDefault;
		}
		
		public var os:String;
		public var version:String;
		public var description:String;
		public var isDefault:Boolean;
		
		public var extensions:Extensions = new Extensions();
		
		public function get ShortId():String
		{
			if(id == null)
				return "";
			return id.name;
		}
		
		/**
		 * In an image like 'emulab-ops//FC6-STD', the OSID would be FC6-STD
		 * @return 
		 * 
		 */
		public function get Osid():String
		{
			var shortId:String = ShortId;
			var idx:int = shortId.indexOf("//");
			if(idx > 0)
				return shortId.substring(idx+2);
			idx = shortId.indexOf(":");
			if(idx > 0)
				return shortId.substring(idx+1);
			return shortId;
		}
		
		/**
		 * In an image like 'emulab-ops//FC6-STD', the domain would be emulab-ops
		 * 
		 * @return 
		 * 
		 */
		public function get Domain():String
		{
			var shortId:String = ShortId;
			var idx:int = shortId.indexOf("//");
			if(idx > 0)
				return shortId.substring(idx+1);
			idx = shortId.indexOf(":");
			if(idx > 0)
				return shortId.substring(idx);
			return shortId;
		}
		
		override public function toString():String
		{
			return "[DiskImage ID="+id.full+"]";
		}
	}
}