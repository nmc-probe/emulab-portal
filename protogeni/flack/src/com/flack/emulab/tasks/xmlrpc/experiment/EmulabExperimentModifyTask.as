package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentModifyTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		// required
		private var proj:String;
		private var exp:String;
		private var nsfilestr:String;
		// optional
		private var reboot:Boolean;
		private var restartEventsys:Boolean;
		public function EmulabExperimentModifyTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newProj:String = "", newExp:String = "", newNsfilestr:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_MODIFY,
				"Get number of used nodes @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"# Nodes Used"
			);
			managerUrl = newManagerUrl;
			proj = newProj;
			exp = newExp;
			nsfilestr = newNsfilestr;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = proj;
			args["exp"] = exp;
			args["nsfilestr"] = nsfilestr;
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