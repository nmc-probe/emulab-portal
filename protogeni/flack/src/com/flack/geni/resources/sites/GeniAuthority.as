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
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.shared.resources.IdentifiableObject;

	/**
	 * GENI Authority
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniAuthority extends IdentifiableObject
	{
		public static const TYPE_PROTOGENI:int = 0;
		public static const TYPE_EMULAB:int = 1;
		
		public var parentAuthority:GeniAuthority;
		
		[Bindable]
		public var name:String;
		[Bindable]
		public var url:String;
		
		[Bindable]
		public var workingCertGet:Boolean = false;
		
		public var userCredential:GeniCredential;
		
		public var type:int;
		
		/**
		 * 
		 * @param id IDN-URN
		 * @param newName Human-readable name
		 * @param newUrl URL for XML-RPC calls
		 * @param newType Type
		 * @param newParentAuthority Parent authority
		 * 
		 */
		public function GeniAuthority(id:String= "",
									  newName:String = "",
									  newUrl:String = "",
									  newType:int = TYPE_PROTOGENI,
									  newParentAuthority:GeniAuthority = null)
		{
			super(id);
			name = newName;
			url = newUrl;
			workingCertGet = false;
			type = newType;
			parentAuthority = newParentAuthority;
		}
		
		override public function toString():String
		{
			return "[GeniAuthority id=" + id.full
				+ " name=" + name
				+ " url=" + url
				+ " workingCertGet=" + workingCertGet + "]";
		}
	}
}