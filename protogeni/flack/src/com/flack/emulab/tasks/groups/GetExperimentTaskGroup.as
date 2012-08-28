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
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentGetVizTask;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentMetadataTask;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentNsFileTask;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentStateTask;
	import com.flack.emulab.tasks.xmlrpc.experiment.EmulabExperimentVirtualTopologyTask;
	import com.flack.shared.tasks.SerialTaskGroup;
	
	/**
	 * Gets all information about an existing slice
	 * 
	 * 1. If resolveSlice and user has authority...
	 *  1a. ResolveSliceSaTask
	 *  1b. GetSliceCredentialSaTask
	 * 2. For each manager...
	 *    If queryAllManagers, or in slice.reportedManagers, or non-ProtoGENI, or no slice authority
	 *  2a. ListSliverResourcesTask/GetSliverCmTask
	 *  2b. ParseManifestTask
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetExperimentTaskGroup extends SerialTaskGroup
	{
		public var experiment:Experiment;
		
		/**
		 * 
		 * @param taskSlice Slice to get everything for
		 * @param shouldResolveSlice Resolve the slice?
		 * @param shouldQueryAllManagers Query all managers? Needed if resources exist at non-ProtoGENI managers.
		 * 
		 */
		public function GetExperimentTaskGroup(taskExperiment:Experiment)
		{
			super(
				"Get " + taskExperiment.name,
				"Gets all infomation about experiment named " + taskExperiment.name
			);
			relatedTo.push(taskExperiment);
			experiment = taskExperiment;
			
			//add(new EmulabExperimentExpInfoTask(experiment));
			//add(new EmulabExperimentInfoTask(experiment));
			add(new EmulabExperimentMetadataTask(experiment));
			
			add(new EmulabExperimentVirtualTopologyTask(experiment));
			add(new EmulabExperimentNsFileTask(experiment));
			add(new EmulabExperimentGetVizTask(experiment));
			add(new EmulabExperimentStateTask(experiment));
		}
	}
}