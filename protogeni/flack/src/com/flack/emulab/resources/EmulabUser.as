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

package com.flack.emulab.resources
{
	import com.flack.emulab.resources.sites.EmulabManager;
	import com.flack.emulab.resources.sites.ProjectCollection;
	import com.flack.emulab.resources.virtual.ExperimentCollection;
	import com.flack.shared.resources.FlackUser;

	/**
	 * Emulab user
	 * 
	 * @author mstrum
	 * 
	 */
	public class EmulabUser extends FlackUser
	{
		[Bindable]
		public var manager:EmulabManager;
		public var projects:ProjectCollection;
		public var experiments:ExperimentCollection;
		
		public function EmulabUser()
		{
			super();
			clear();
		}
		
		public function clear():void
		{
			projects = new ProjectCollection();
			experiments = new ExperimentCollection();
		}
	}
}