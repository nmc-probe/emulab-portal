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

package com.flack.emulab.tasks.groups
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentGetListTask;
	import com.flack.emulab.tasks.xmlrpc.user.EmulabUserMembershipTask;
	import com.flack.shared.tasks.SerialTaskGroup;
	
	/**
	 * Gets the list of user info (slices, keys, etc.)
	 * @author mstrum
	 * 
	 */
	public class ResolveUserTaskGroup extends SerialTaskGroup
	{
		public function ResolveUserTaskGroup()
		{
			super(
				"Resolve " + EmulabMain.user.name,
				"Resolves " + EmulabMain.user.name + " at all authorities"
			);
			relatedTo.push(EmulabMain.user);
			add(new EmulabUserMembershipTask());
			add(new EmulabExperimentGetListTask());
		}
	}
}