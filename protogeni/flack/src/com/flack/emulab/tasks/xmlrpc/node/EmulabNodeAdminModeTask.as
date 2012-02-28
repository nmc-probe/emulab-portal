package com.geni.tasks.xmlrpc.emulab.node
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabNodeAvailableTask extends EmulabXmlrpcTask
	{
		static public const MODE_ON:String = "on";
		static public const MODE_ON:String = "off";
		
		private var managerUrl:String = "";
		private var node:String;
		private var mode:String;
		// optional
		private var reboot:Boolean = true;
		public function EmulabNodeAvailableTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newNode:String = "", newMode:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_NODE,
				EmulabXmlrpcTask.METHOD_ADMINMODE,
				"Get node availability @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"Get node availability"
			);
			managerUrl = newManagerUrl;
			node = newNode;
			mode = newMode;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["node"] = node;
			args["mode"] = mode;
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