package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.shared.tasks.ParallelTaskGroup;
	
	/**
	 * Adds MC Nodes everywhere without actually updating slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public class AddMCNodesTaskGroup extends ParallelTaskGroup
	{
		public var details:SliceInstoolsDetails;
		public function AddMCNodesTaskGroup(newDetails:SliceInstoolsDetails)
		{
			super(
				"Add MC Nodes",
				"Adds MC Nodes to all slivers"
			);
			relatedTo.push(newDetails.slice);
			details = newDetails;
			
			for each(var sliver:Sliver in details.slice.slivers.collection)
			{
				if(Instools.devel_version[sliver.manager.id.full] != null)
					add(new AddMCNodeTask(sliver, details));
				else
				{	
					addMessage(
						"Skipping " + sliver.manager.hrn,
						"MC Node was not added to " + sliver.manager.hrn + " because INSTOOLS was not detected there"
					);
				}
			}
		}
	}
}