package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentSaveLogsTask extends EmulabXmlrpcTask
	{
		static public const ACTION_START:String = "start";
		static public const ACTION_STOP:String = "stop";
		static public const ACTION_REPLAY:String = "replay";
		
		private var managerUrl:String = "";
		private var proj:String;
		private var exp:String;
		private var action:String;
		public function EmulabExperimentSaveLogsTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newProj:String = "", newExp:String = "", newAction:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_SAVELOGS,
				"Get number of used nodes @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"# Nodes Used"
			);
			managerUrl = newManagerUrl;
			proj = newProj;
			exp = newExp;
			action = newAction;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = proj;
			args["exp"] = exp;
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}