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
			// Slice is ready, instrumentize/check for status
			else if(task is RefreshSliceStatusTaskGroup)
			{
				add(new PollInstoolsStatusTaskGroup(details));
			}
			super.completedTask(task);
		}
	}
}