package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	
	/**
	 * Gets the INSTOOLS version for a manager on which a sliver will be or was created
	 * 
	 * @author mstrum
	 * 
	 */
	public final class InstoolsVersionTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var details:SliceInstoolsDetails;
		
		public function InstoolsVersionTask(newSliver:Sliver, sliceDetails:SliceInstoolsDetails)
		{
			super(newSliver.manager.url,
				Instools.instoolsModule + "/" + sliceDetails.apiVersion.toFixed(1),
				Instools.getInstoolsVersion,
				"Get INSTOOLS version @ " + newSliver.manager.hrn,
				"Requesting current INSTOOLS version at " + newSliver.manager.hrn,
				"Get INSTOOLS version"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.manager);
			relatedTo.push(newSliver.slice);
			sliver = newSliver;
			details = sliceDetails;
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=true):void
		{
			if (code ==  ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				Instools.devel_version[sliver.manager.id.full] = String(data.devel_version);
				Instools.stable_version[sliver.manager.id.full] = String(data.stable_version);
				
				addMessage(
					"Got INSTOOLS version",
					"Uses Devel v" + Instools.devel_version[sliver.manager.id.full]
					+ " and stable v" + Instools.stable_version[sliver.manager.id.full],
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
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
			Instools.devel_version[sliver.manager.id.full] = null;
			Instools.stable_version[sliver.manager.id.full] = null;
			
			addMessage(
				"INSTOOLS not available",
				"The call to get the INSTOOLS version failed, assuming INSTOOLS is not available",
				LogMessage.LEVEL_WARNING,
				LogMessage.IMPORTANCE_HIGH
			);
		}
	}
}