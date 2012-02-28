package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	// print physical mapping of nodes in an experiment
	public class EmulabExperimentInfoTask extends EmulabXmlrpcTask
	{
		static public const ASPECT_MAPPING:String = "mapping";
		static public const ASPECT_LINKS:String = "links";
		
		private var experiment:Experiment;
		private var aspect:String;
		public function EmulabExperimentInfoTask(newExperiment:Experiment, newAspect:String = "")
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_INFO,
				"Get number of used nodes",
				"Getting node availability" ,
				"# Nodes Used"
			);
			experiment = newExperiment;
			aspect = newAspect;
			relatedTo.push(experiment);
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = experiment.pid;
			args["exp"] = experiment.name;
			args["aspect"] = aspect;
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