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

package com.flack.geni.tasks.groups
{
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.ResolveUserSaTask;
	import com.flack.shared.tasks.ParallelTaskGroup;
	
	/**
	 * Gets the list of user info (slices, keys, etc.)
	 * @author mstrum
	 * 
	 */
	public class ResolveUserTaskGroup extends ParallelTaskGroup
	{
		public var user:GeniUser;
		
		public function ResolveUserTaskGroup(newUser:GeniUser)
		{
			super(
				"Resolve " + newUser.name,
				"Resolves " + newUser.name + " at all authorities"
			);
			user = newUser;
			
			if(newUser.authority.type == GeniAuthority.TYPE_PROTOGENI)
				add(new ResolveUserSaTask(user, user.authority));
		}
	}
}