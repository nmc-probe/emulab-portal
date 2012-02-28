package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.virtual.Experiment;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentReloadTask extends EmulabXmlrpcTask
	{
		private var experiment:Experiment;
		// optional
		private var imagename:String;
		private var imageproj:String;
		private var imageid:String;
		private var reboot:Boolean;
		public function EmulabExperimentReloadTask(newExperiment:Experiment,
												   newImagename:String = "",
												   newImageproj:String = "",
												   newImageid:String = "",
												   newReboot:Boolean = false)
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_RELOAD,
				"Get number of used nodes",
				"Getting node availability",
				"# Nodes Used"
			);
			experiment = newExperiment;
			imagename = newImagename;
			imageproj = newImageproj;
			imageid = newImageid;
			reboot = newReboot;
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