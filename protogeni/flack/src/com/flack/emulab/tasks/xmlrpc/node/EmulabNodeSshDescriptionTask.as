package com.flack.emulab.tasks.xmlrpc.node
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabNodeSshDescriptionTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		private var node:String;
		public function EmulabNodeSshDescriptionTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newNode:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_NODE,
				EmulabXmlrpcTask.METHOD_SSHDESCRIPTION,
				"Get node availability @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"Get node availability"
			);
			managerUrl = newManagerUrl;
			node = newNode;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["node"] = node;
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