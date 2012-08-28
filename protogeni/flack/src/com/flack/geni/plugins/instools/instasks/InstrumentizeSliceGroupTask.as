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
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.tasks.groups.slice.RefreshSliceStatusTaskGroup;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	
	/**
	 * 1. InstoolsVersionsTaskGroup
	 * 		- Get the INSTOOLS versions of the managers
	 * 2. AddMCNodesTaskGroup
	 * 		- Get the new RSPECs at all of the managers
	 * 3. CreateMCNodesTaskGroup
	 * 		- Submit the new RSPECs as needed
	 * 4. RefreshSliceStatusTaskGroup
	 * 		- Make sure the slice is ready
	 * 5. PollInstoolsStatusTaskGroup
	 * 		- Instrumentize everything
	 * 
	 * @author mstrum
	 * 
	 */
	public final class InstrumentizeSliceGroupTask extends SerialTaskGroup
	{
		public var details:SliceInstoolsDetails;
		
		public function InstrumentizeSliceGroupTask(newDetails:SliceInstoolsDetails)
		{
			super(
				"Instrumentize",
				"Instrumentizes the slice"
			);
			relatedTo.push(newDetails.slice);
			details = newDetails;
			
			details.slice.clearStatus();
			
			add(new InstoolsVersionsTaskGroup(details));
		}
		
		override public function completedTask(task:Task):void
		{
			// Got the versions, start adding MC Nodes
			if(task is InstoolsVersionsTaskGroup)
			{
				if(details.creating)
					add(new AddMCNodesTaskGroup(details));
				else
					add(new PollInstoolsStatusTaskGroup(details));
			}
				// Added the nodes, go ahead and create
			else if(task is AddMCNodesTaskGroup)
			{
				add(new CreateMCNodesTaskGroup(details));
			}
				// Created the MC Nodes, make sure slice is ready
			else if(task is CreateMCNodesTaskGroup)
			{
				add(new RefreshSliceStatusTaskGroup(details.slice));
			}
				// Send the manifests to the CMs.
			else if(task is RefreshSliceStatusTaskGroup)
			{
				add(new SaveManifestTaskGroup(details));
			}
				// Slice is ready, instrumentize/check for status
			else if(task is SaveManifestTaskGroup)
			{
				add(new PollInstoolsStatusTaskGroup(details));
			}
			super.completedTask(task);
		}
	}
}