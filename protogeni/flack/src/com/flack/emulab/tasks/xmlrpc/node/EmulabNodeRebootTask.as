package com.flack.emulab.tasks.xmlrpc.node
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabNodeRebootTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		// required
		private var nodes:Vector.<String>;
		// optional
		private var reconfig:Boolean = false;
		private var power:Boolean = false;
		public function EmulabNodeRebootTask(newNodes:Vector.<String>, newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_NODE,
				EmulabXmlrpcTask.METHOD_REBOOT,
				"Get node availability @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"Get node availability"
			);
			managerUrl = newManagerUrl;
			nodes = newNodes;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["nodes"] = nodes.join(",");
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