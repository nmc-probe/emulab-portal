package com.flack.geni.plugins.ontime.ottasks
{
	import com.adobe.crypto.SHA1;
	import com.flack.geni.GeniMain;
	import com.flack.geni.plugins.ontime.Ontime;
	import com.flack.geni.plugins.ontime.SliceOntimeDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	
	import mx.controls.Alert;
	
	public final class InstrumentizeTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var details:SliceOntimeDetails;
		
		public function InstrumentizeTask(newSliver:Sliver, useDetails:SliceOntimeDetails)
		{
			super(
				newSliver.manager.url,
				Ontime.instoolsModule + "/" + useDetails.apiVersion.toFixed(1),
				Ontime.instrumentize,
				"Instrumentize @ " + newSliver.manager.hrn,
				"Instrumentizing the experiment on " + newSliver.manager.hrn,
				"Instrumentize"
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
			addNamedField("password", SHA1.hash(GeniMain.geniUniverse.user.password));
			addNamedField("INSTOOLS_VERSION",Ontime.devel_version[sliver.manager.id.full]);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			addMessage(
				"Instrumentize started...",
				"Instrumentize started...",
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			super.afterComplete(false);
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
				"Instrumentize starting failed!",
				"Instrumentize starting failed!",
				LogMessage.LEVEL_FAIL,
				LogMessage.IMPORTANCE_HIGH
			);
			Alert.show("Failed to Instrumentize on " + sliver.manager.hrn + ". ", "Problem instrumentizing");
		}
	}
}