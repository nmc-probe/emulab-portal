package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentStateTask extends EmulabXmlrpcTask
	{
		private var experiment:Experiment;
		public function EmulabExperimentStateTask(newExperiment:Experiment)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_STATE,
				"Get number of used nodes @ " + EmulabMain.manager.api.url,
				"Getting node availability at " + EmulabMain.manager.api.url,
				"# Nodes Used"
			);
			experiment = newExperiment;
			relatedTo.push(experiment);
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = experiment.pid;
			args["exp"] = experiment.name
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				experiment.state = data;
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_EXPERIMENT,
					experiment,
					FlackEvent.ACTION_STATUS
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}