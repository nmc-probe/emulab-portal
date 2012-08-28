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
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.resources.sites.GeniAuthorityCollection;
	import com.flack.geni.resources.virtual.SliceCollection;
	import com.flack.shared.resources.FlackUser;

	/**
	 * GENI user
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniUser extends FlackUser
	{
		[Bindable]
		public var authority:GeniAuthority;
		public var subAuthorities:GeniAuthorityCollection = new GeniAuthorityCollection();
		
		[Bindable]
		public var credential:GeniCredential;
		
		public var keys:Vector.<String> = new Vector.<String>();
		
		public var slices:SliceCollection = new SliceCollection();
		
		public function GeniUser()
		{
			super();
		}
		
		public function get HasCredential():Boolean
		{
			return credential != null;
		}
	}
}