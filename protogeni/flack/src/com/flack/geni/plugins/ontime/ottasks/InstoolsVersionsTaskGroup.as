package com.flack.geni.plugins.ontime.ottasks
{
	import com.flack.geni.plugins.ontime.Ontime;
	import com.flack.geni.plugins.ontime.SliceOntimeDetails;
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
		public var details:SliceOntimeDetails;
		public function InstoolsVersionsTaskGroup(newDetails:SliceOntimeDetails)
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
				if(Ontime.devel_version[sliver.manager.id.full] == null)
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