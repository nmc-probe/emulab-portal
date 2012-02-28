package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	// get information about an experiment
	public class EmulabExperimentGetVizTask extends EmulabXmlrpcTask
	{
		static public const SHOW_NODEINFO:String = "nodeinfo";
		static public const SHOW_MAPPING:String = "mapping";
		static public const SHOW_LINKINFO:String = "linkinfo";
		static public const SHOW_SHAPING:String = "shaping";
		
		private var experiment:Experiment;
		public function EmulabExperimentGetVizTask(newExperiment:Experiment)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_GETVIZ,
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
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}