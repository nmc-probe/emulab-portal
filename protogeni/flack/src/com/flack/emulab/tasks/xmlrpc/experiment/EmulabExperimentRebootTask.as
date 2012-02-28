package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentRebootTask extends EmulabXmlrpcTask
	{
		private var experiment:Experiment;
		// optional
		private var reconfig:Boolean;
		private var power:Boolean;
		public function EmulabExperimentRebootTask(newExperiment:Experiment, newReconfig:Boolean = false, newPower:Boolean = false)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_REBOOT,
				"Get number of used nodes",
				"Getting node availability",
				"# Nodes Used"
			);
			experiment = newExperiment;
			reconfig = newReconfig;
			power = newPower;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = experiment.pid;
			args["exp"] = experiment.name;
			// XXX
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