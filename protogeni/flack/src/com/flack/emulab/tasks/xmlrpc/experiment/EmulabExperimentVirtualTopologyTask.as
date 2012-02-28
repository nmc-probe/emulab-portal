package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	
	import flash.utils.Dictionary;
	
	// get information about an experiment
	public class EmulabExperimentVirtualTopologyTask extends EmulabXmlrpcTask
	{
		private var experiment:Experiment;
		public function EmulabExperimentVirtualTopologyTask(newExperiment:Experiment)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_VIRTUALTOPOLOGY,
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
			args["exp"] = experiment.name;
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				// The return value is a hash table (Dictionary) of hash tables
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_EXPERIMENT,
					experiment,
					FlackEvent.ACTION_POPULATED
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}