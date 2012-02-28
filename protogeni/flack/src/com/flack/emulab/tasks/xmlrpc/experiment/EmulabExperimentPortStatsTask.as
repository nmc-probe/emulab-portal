package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	// print physical mapping of nodes in an experiment
	public class EmulabExperimentPortStatsTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		private var proj:String;
		private var exp:String;
		public function EmulabExperimentPortStatsTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newProj:String = "", newExp:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_PORTSTATS,
				"Get number of used nodes @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"# Nodes Used"
			);
			managerUrl = newManagerUrl;
			proj = newProj;
			exp = newExp;
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
				// The return value is a hash table (Dictionary) of hash tables
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}