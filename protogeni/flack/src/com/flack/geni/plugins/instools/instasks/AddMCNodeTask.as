package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.plugins.emulab.EmulabOpenVzSliverType;
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.tasks.TaskError;
	
	import mx.controls.Alert;
	
	/**
	 * Calls INSTOOLS and gets the information needed to add a MC Node into a sliver
	 * 
	 * @author mstrum
	 * 
	 */
	public final class AddMCNodeTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var details:SliceInstoolsDetails;
		
		public function AddMCNodeTask(newSliver:Sliver, useDetails:SliceInstoolsDetails)
		{
			super(newSliver.manager.url,
				Instools.instoolsModule + "/" + useDetails.apiVersion.toFixed(1),
				Instools.addMCNode,
				"Add MC Node @ " + newSliver.manager.hrn,
				"Allocating a measurement controller at " + newSliver.manager.hrn,
				"Add MC Node"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.manager);
			relatedTo.push(newSliver.slice);
			sliver = newSliver;
			details = useDetails;
		}
		
		override protected function createFields():void
		{
			addNamedField("urn", sliver.slice.id.full);
			addNamedField("virtualMC", details.useVirtualMCs ? sliver.manager.supportedSliverTypes.Shared.length > 0 : 0);
			addNamedField("INSTOOLS_VERSION", details.useStableINSTOOLS ? Instools.stable_version[sliver.manager.id.full] : Instools.devel_version[sliver.manager.id.full]);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=true):void
		{
			if (code ==  ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				// Determine the sliver where the MC node will exist
				var parseSliver:Sliver = sliver;
				if(data.cmurn_to_contact != null)
				{
					var mcManager:GeniManager = GeniMain.geniUniverse.managers.getById(String(data.cmurn_to_contact));
					if(mcManager == null)
					{
						// XXX error, manager not available
					}
					parseSliver = sliver.slice.slivers.getOrCreateByManager(mcManager, sliver.slice);
					details.cmurn_to_contact[sliver.manager.id.full] = parseSliver.manager.id.full;
				}
				Instools.mcLocation[sliver.manager.id.full] = parseSliver.manager.id.full;
				details.MC_present[sliver.manager.id.full] = Boolean(data.wasMCpresent);
				if (details.MC_present[sliver.manager.id.full]) 
				{
					addMessage(
						"MC Node already added",
						"Nothing to do, sliver already has MC Node",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
				} 
				else 
				{
					var newRspec:Rspec = new Rspec(String(data.instrumentized_rspec));
					
					details.updated_rspec[sliver.manager.id.full] = newRspec.document;
					details.rspec_version[sliver.manager.id.full] = String(data.rspec_version);
					
					// Parse into slice with unsubmitted changes
					var parse:ParseRequestManifestTask = new ParseRequestManifestTask(parseSliver, newRspec, true, true);
					parse.start();
					
					addMessage(
						"Recieved new request with MC Node added",
						sliver.manager.hrn + " returned a new RSPEC to add a MC Node:\n" + details.updated_rspec[sliver.manager.id.full],
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
				}
				
				super.afterComplete(false);
			}
			else
				faultOnSuccess();
		}
		
		override protected function afterError(taskError:TaskError):void
		{
			failed();
			super.afterError(taskError);
		}
		
		override protected function runCancel():void
		{
			failed();
		}
		
		public function failed():void
		{
			addMessage(
				"Add MC Node failed",
				"Add MC Node failed",
				LogMessage.LEVEL_FAIL,
				LogMessage.IMPORTANCE_HIGH
			);
			Alert.show(
				"There was a problem adding the MC Node on " + sliver.manager.hrn + ". ",
				"Problem adding MC Node"
			);
		}
	}
}