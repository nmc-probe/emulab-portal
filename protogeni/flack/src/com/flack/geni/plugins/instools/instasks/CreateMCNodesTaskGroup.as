package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.groups.slice.SubmitSliceTaskGroup;
	import com.flack.geni.tasks.xmlrpc.am.CreateSliverTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.CreateSliverCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.RedeemTicketCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.UpdateSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.Task;
	
	import mx.controls.Alert;
	
	/**
	 * Takes all the information from the added MC Nodes and actually updates the slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public final class CreateMCNodesTaskGroup extends ParallelTaskGroup
	{
		public var details:SliceInstoolsDetails;
		private var prompting:Boolean = false;
		private var deletingAfterProblem:Boolean = false;
		public function CreateMCNodesTaskGroup(newDetails:SliceInstoolsDetails)
		{
			super(
				"Allocate MC Nodes",
				"Allocates all of the MC Nodes which were added"
			);
			relatedTo.push(newDetails.slice);
			details = newDetails;
			
			if(details.creating)
			{
				if(details.slice.UnsubmittedChanges)
					add(new SubmitSliceTaskGroup(newDetails.slice, false));
				else
				{
					// XXX no changes?
				}
			}
		}
		
		override public function completedTask(task:Task):void
		{
			for each(var sliver:Sliver in details.slice.slivers.collection)
			{
				if(details.cmurn_to_contact[sliver.manager.id.full] == null || details.cmurn_to_contact[sliver.manager.id.full] == sliver.manager.id.full)
					details.MC_present[sliver.manager.id.full] = Instools.doesSliverHaveMc(sliver);
				else
				{
					var otherSliver:Sliver = details.slice.slivers.getByManager(GeniMain.geniUniverse.managers.getById(details.cmurn_to_contact[sliver.manager.id.full]));
					details.MC_present[sliver.manager.id.full] = Instools.doesSliverHaveJuniperMc(otherSliver);
					/*
					for (var key:String in Instools.mcLocation)
					{
					if (Instools.mcLocation[key] == otherSliver.manager.id.full)
					{
					details.MC_present[key] = otherSliver.sliver.Created;
					}
					}*/
					if (Instools.devel_version[otherSliver.manager.id.full] == null)
						add(new InstoolsVersionTask(otherSliver, details));
				}
			}
			super.completedTask(task);
		}
		
		override public function erroredTask(task:Task):void
		{
			Alert.show("Problem!");
			super.erroredTask(task);
		}
		
		override public function canceledTask(task:Task):void
		{
			Alert.show("Problem!");
			super.erroredTask(task);
		}
	}
}
//