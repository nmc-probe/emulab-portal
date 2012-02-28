package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentNsCheckTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		public function EmulabExperimentNsCheckTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_NSCHECK,
				"Get number of used nodes @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"# Nodes Used"
			);
			managerUrl = newManagerUrl;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			//args["nsfilestr"] = ??;
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				//The return code is RESPONSE_SUCCESS or RESPONSE_ERROR.
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}