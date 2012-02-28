package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	// get information about an experiment
	public class EmulabExperimentExpInfoTask extends EmulabXmlrpcTask
	{
		static public const SHOW_NODEINFO:String = "nodeinfo";
		static public const SHOW_MAPPING:String = "mapping";
		static public const SHOW_LINKINFO:String = "linkinfo";
		static public const SHOW_SHAPING:String = "shaping";
		
		private var experiment:Experiment;
		private var show:Array;
		public function EmulabExperimentExpInfoTask(newExperiment:Experiment, newShow:Array)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_EXPINFO,
				"Get number of used nodes",
				"Getting node availability",
				"# Nodes Used"
			);
			experiment = newExperiment;
			show = newShow;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = experiment.pid;
			args["exp"] = experiment.name;
			args["show"] = show.join(',');
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