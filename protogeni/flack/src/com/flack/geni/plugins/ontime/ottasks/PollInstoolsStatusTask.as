package com.flack.geni.plugins.ontime.ottasks
{
	import com.flack.geni.plugins.ontime.Ontime;
	import com.flack.geni.plugins.ontime.SliceOntimeDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.StartSliverCmTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.MathUtil;
	
	import mx.controls.Alert;
	
	public final class PollInstoolsStatusTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var details:SliceOntimeDetails;
		
		public function PollInstoolsStatusTask(newSliver:Sliver, useDetails:SliceOntimeDetails)
		{
			super(
				newSliver.manager.url,
				Ontime.instoolsModule + "/" + useDetails.apiVersion.toFixed(1),
				Ontime.getInstoolsStatus,
				"Poll Instools Status @ " + newSliver.manager.hrn,
				"Getting the sliver status on " + newSliver.manager.hrn + " on slice named " + newSliver.slice.Name,
				"Poll INSTOOLS Status"
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
			addNamedField("INSTOOLS_VERSION",Ontime.devel_version[sliver.manager.id.full]);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code ==  ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				details.instools_status[sliver.manager.id.full] = String(data.status);
				var status:String = String(data.status);
				switch(status) {
					case "INSTRUMENTIZE_COMPLETE":		//instrumentize is finished, experiment is ready, etc.
						details.portal_url[sliver.manager.id.full] = String(data.portal_url);
						sliver.status = Sliver.STATUS_READY;
						var msg:String = details.creating ? "Instrumentizing complete!" : "INSTOOLS running!";
						addMessage(
							msg,
							msg,
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						super.afterComplete(addCompletedMessage);
						return;
					case "INSTALLATION_COMPLETE":		//MC has finished the startup scripts
						addMessage(
							"Instrumentize scripts installed...",
							"Instrumentize scripts installed...",
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						if (details.started_instrumentize[sliver.manager.id.full] != "1")
						{
							addMessage(
								"Instrumentizing...",
								"Instrumentizing...",
								LogMessage.LEVEL_INFO,
								LogMessage.IMPORTANCE_HIGH
							);
							parent.add(new InstrumentizeTask(sliver, details));
							details.started_instrumentize[sliver.manager.id.full] = "1";
						}
						break;
					case "MC_NOT_STARTED":				//MC has been added, but not started
						addMessage(
							"MC not started...",
							"MC not started...",
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						if (details.started_MC[sliver.manager.id.full] != "1")
						{
							addMessage(
								"Starting...",
								"Starting...",
								LogMessage.LEVEL_INFO,
								LogMessage.IMPORTANCE_HIGH
							);
							parent.add(new StartSliverCmTask(sliver));
							details.started_MC[sliver.manager.id.full] = "1";
						}
						break;
					case "INSTRUMENTIZE_IN_PROGRESS":	//the instools server has started instrumentizing the nodes
						addMessage(
							"Instrumentize in progress...",
							"Instrumentize in progress...",
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						break;
					case "INSTALLATION_IN_PROGRESS":	//MC is running it's startup scripts
						addMessage(
							"Instrumentize installing...",
							"Instrumentize installing...",
							LogMessage.LEVEL_INFO,
							LogMessage.IMPORTANCE_HIGH
						);
						break;
					case "MC_NOT_PRESENT":				//The addMC/updatesliver calls haven't finished 
						addMessage(
							"MC Node not added yet...",
							"MC Node not added yet...",
							LogMessage.LEVEL_WARNING,
							LogMessage.IMPORTANCE_HIGH
						);
						break;
					case "MC_UNSUPPORTED_OS":
						addMessage(
							"Unsupported OS! Maybe not booted...",
							"Unsupported OS! Maybe not booted...",
							LogMessage.LEVEL_WARNING,
							LogMessage.IMPORTANCE_HIGH
						);
						break;
					default:
						sliver.status = Sliver.STATUS_FAILED;
						addMessage(
							status + "!",
							status + "!"
						);
						Alert.show("Unrecognized INSTOOLS status: " + status);
						afterError(
							new TaskError(
								"Unrecognized INSTOOLS status: " + status,
								TaskError.FAULT,
								status
							)
						);
						return;
				}
				
				// At this point, still changing and polling...
				sliver.status = Sliver.STATUS_CHANGING;
				delay = MathUtil.randomNumberBetween(20, 60);
				runCleanup();
				start();
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