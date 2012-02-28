package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentSwapExpTask extends EmulabXmlrpcTask
	{
		static public const DIRECTION_IN:String = "in";
		static public const DIRECTION_OUT:String = "out";
		
		private var experiment:Experiment;
		private var direction:String;
		public function EmulabExperimentSwapExpTask(newExperiment:Experiment, newDirection:String)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_SWAPEXP,
				"Get number of used nodes",
				"Getting node availability",
				"# Nodes Used"
			);
			experiment = newExperiment;
			direction = newDirection;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = experiment.pid;
			args["exp"] = experiment.name;
			args["direction"] = direction;
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				// XXX
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}