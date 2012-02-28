package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentEventSysControlTask extends EmulabXmlrpcTask
	{
		static public const OP_START:String = "start";
		static public const OP_STOP:String = "stop";
		static public const OP_REPLAY:String = "replay";
		
		private var managerUrl:String = "";
		private var proj:String;
		private var exp:String;
		private var op:String;
		public function EmulabExperimentEventSysControlTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newProj:String = "", newExp:String = "", newOp:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_EVENTSYSCONTROL,
				"Get number of used nodes @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"# Nodes Used"
			);
			managerUrl = newManagerUrl;
			proj = newProj;
			exp = newExp;
			op = newOp;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = proj;
			args["exp"] = exp;
			args["op"] = op;
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