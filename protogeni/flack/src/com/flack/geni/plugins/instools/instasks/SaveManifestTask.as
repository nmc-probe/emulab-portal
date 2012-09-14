package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.GenerateRequestManifestTask;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.StartSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.MathUtil;
	
	import mx.controls.Alert;
	
	public final class SaveManifestTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var details:SliceInstoolsDetails;
		public var manifest:Rspec;
		
		public function SaveManifestTask(newSliver:Sliver, useDetails:SliceInstoolsDetails, newManifest:Rspec)
		{
			super(
				newSliver.manager.url,
				Instools.instoolsModule + "/" + useDetails.apiVersion.toFixed(1),
				Instools.saveManifest,
				"Save Manifest @ " + newSliver.manager.hrn,
				"Saving manifest on " + newSliver.manager.hrn + " on slice named " + newSliver.slice.Name,
				"Save Manifest"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.manager);
			relatedTo.push(newSliver.slice);
			sliver = newSliver;
			details = useDetails;
			manifest = newManifest;
		}
		
		override protected function createFields():void
		{
			addNamedField("urn", sliver.slice.id.full);
			addNamedField("INSTOOLS_VERSION", details.useStableINSTOOLS ? Instools.stable_version[sliver.manager.id.full] : Instools.devel_version[sliver.manager.id.full]);
			//addNamedField("INSTOOLS_VERSION",Instools.devel_version[sliver.manager.id.full]);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
			addNamedField("manifest",manifest.document);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code ==  ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				addMessage(
					"Manifest Saved",
					"Saved manifest on " + sliver.manager.hrn,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				super.afterComplete(addCompletedMessage);
				return;
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
				"Poll INSTOOLS status failed",
				"Poll INSTOOLS status failed",
				LogMessage.LEVEL_FAIL,
				LogMessage.IMPORTANCE_HIGH
			);
			Alert.show(
				"Failed to poll INSTOOLS status on " + sliver.manager.hrn + ". ",
				"Problem polling INSTOOLS status"
			);
		}
	}
}