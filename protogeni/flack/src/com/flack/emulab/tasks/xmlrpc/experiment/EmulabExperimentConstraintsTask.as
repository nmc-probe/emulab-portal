package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	import com.flack.geni.resources.sites.GeniManager;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentConstraintsTask extends EmulabXmlrpcTask
	{
		private var manager:GeniManager;
		public function EmulabExperimentConstraintsTask(newManager:GeniManager)
		{                                                                   
			super(
				manager.api.url,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_CONSTRAINTS,
				"Gets the physical/policy constraints for experiment perameters @ " + manager.api.url,
				"Gets the physical/policy constraints for experiment perameters @ " + manager.api.url,
				"Get contraints"
			);
			manager = newManager;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				// data["idle/threshold"]
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}