/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group,
* University of Kentucky and the Laboratory for Advanced Networking.
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

package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.shared.tasks.ParallelTaskGroup;
	
	/**
	 * Gets the INSTOOLS version info for all managers used in the slice
	 * 
	 * @author mstrum
	 * 
	 */
	public final class InstoolsVersionsTaskGroup extends ParallelTaskGroup
	{
		public var details:SliceInstoolsDetails;
		public function InstoolsVersionsTaskGroup(newDetails:SliceInstoolsDetails)
		{
			super(
				"Get INSTOOLS versions",
				"Gets the INSTOOLS versions at all the managers for the slice"
			);
			relatedTo.push(newDetails.slice);
			details = newDetails;
			
			//details.clear();
			
			// Make sure a sliver exists in the slice for any we will be working on...
			for each(var manager:GeniManager in details.slice.nodes.Managers.collection)
			{
				var sliver:Sliver = details.slice.slivers.getOrCreateByManager(manager, details.slice);
				// Try to get INSTOOLS version on managers we don't have any data on
				if(Instools.devel_version[sliver.manager.id.full] == null)
					add(new InstoolsVersionTask(sliver, details));
				else
				{
					addMessage(
						"Skipping " + sliver.manager.hrn,
						"Skipping " + sliver.manager.hrn + " which already reported its INSTOOLS version"
					);
				}
			}
		}
	}
}