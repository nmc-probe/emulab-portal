package com.flack.geni.plugins.ontime.ottasks
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.plugins.ontime.SliceOntimeDetails;
	import com.flack.geni.resources.virtual.Sliver;
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
		public var details:SliceOntimeDetails;
		private var prompting:Boolean = false;
		private var deletingAfterProblem:Boolean = false;
		public function CreateMCNodesTaskGroup(newDetails:SliceOntimeDetails)
		{
			super(
				"Allocate MC Nodes",
				"Allocates all of the MC Nodes which were added"
			);
			relatedTo.push(newDetails.slice);
			details = newDetails;
			
			for each(var sliver:Sliver in details.slice.slivers.collection)
			{
				if(details.MC_present[sliver.manager.id.full] != null
					&& !details.MC_present[sliver.manager.id.full])
				{
					var sliverToContact:Sliver;
					if(details.cmurn_to_contact[sliver.manager.id.full] != null)
						sliverToContact = details.slice.slivers.getOrCreateByManager(GeniMain.geniUniverse.managers.getById(details.cmurn_to_contact[sliver.manager.id.full]) , details.slice);
					else
						sliverToContact = sliver;
					var newRspec:Rspec = new Rspec(new XML(details.updated_rspec[sliver.manager.id.full]));
					if(details.creating)
					{
						if(sliverToContact.Created)
						{
							if(sliverToContact.manager.api.type == ApiDetails.API_PROTOGENI && sliverToContact.manager.api.level == ApiDetails.LEVEL_FULL)
								add(new UpdateSliverCmTask(sliver, newRspec));
							else
							{
								addMessage(
									"Couldn't update " + sliverToContact.manager.hrn,
									sliverToContact.manager.hrn + " either doesn't use the protogeni api or does not support the full api",
									LogMessage.LEVEL_WARNING
								);
							}
						}
						else
						{
							if(sliverToContact.manager.api.type == ApiDetails.API_GENIAM)
								add(new CreateSliverTask(sliverToContact, newRspec));
							else
								add(new CreateSliverCmTask(sliver, newRspec));
						}
					}
					else
					{
						Alert.show("Adding MC Nodes before slivers are created is not currently supported!");
						// XXX nothing to do for now, we don't support not creating slivers / adding MC nodes before slivers are created
						// TODO in the future probably just import MC Nodes without submitting
					}
				}
				else
				{
					addMessage(
						"Nothing to do",
						"Nothing to do for " + sliver.manager.hrn
					);
				}
			}
		}
		
		override public function completedTask(task:Task):void
		{
			// Got the versions, start adding MC Nodes
			if(task is RedeemTicketCmTask)
			{
				var redeemTask:RedeemTicketCmTask = task as RedeemTicketCmTask;
				details.MC_present[redeemTask.sliver.manager.id.full] = redeemTask.success;
			}
			super.completedTask(task);
		}
		
		override public function erroredTask(task:Task):void
		{
			var msg:String = "";
			if(task is UpdateSliverCmTask)
				msg = " updating sliver on " + (task as UpdateSliverCmTask).sliver.manager.hrn;
			else if(task is RedeemTicketCmTask)
				msg = " redeeming ticket on " + (task as RedeemTicketCmTask).sliver.manager.hrn;
			if(msg.length > 0)
				Alert.show("Problem" + msg + ". To instrumentize this sliver, try instrumentizing at a later time.  INSTOOLS will continue instrumenting the other slivers.");
			super.erroredTask(task);
		}
	}
}
//