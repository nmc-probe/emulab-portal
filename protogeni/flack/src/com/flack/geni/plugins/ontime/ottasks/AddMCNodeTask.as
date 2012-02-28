package com.flack.geni.plugins.ontime.ottasks
{
	import com.flack.geni.plugins.ontime.Ontime;
	import com.flack.geni.plugins.ontime.SliceOntimeDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
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
		public var details:SliceOntimeDetails;
		
		public function AddMCNodeTask(newSliver:Sliver, useDetails:SliceOntimeDetails)
		{
			super(newSliver.manager.url,
				Ontime.instoolsModule + "/" + useDetails.apiVersion.toFixed(1),
				Ontime.addMCNode,
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
			addNamedField("virtualMC", details.useVirtualMCs ? sliver.manager.supportsUnboundVmNodes : 0);
			addNamedField("INSTOOLS_VERSION",Ontime.devel_version[sliver.manager.id.full]);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=true):void
		{
			if (code ==  ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				if(data.cmurn_to_contact != null)
					details.cmurn_to_contact[sliver.manager.id.full] = String(data.cmurn_to_contact);
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
					details.updated_rspec[sliver.manager.id.full] = String(data.instrumentized_rspec);
					details.rspec_version[sliver.manager.id.full] = String(data.rspec_version);
					
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