package com.flack.emulab.tasks.xmlrpc.node
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabNodeCreateImageTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		private var node:String;
		private var imagename:String;
		// optional
		private var imageproj:String;
		public function EmulabNodeCreateImageTask(newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed", newNode:String = "", newImagename:String = "")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_NODE,
				EmulabXmlrpcTask.METHOD_CREATEIMAGE,
				"Get node availability @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"Get node availability"
			);
			managerUrl = newManagerUrl;
			node = newNode;
			imagename = newImagename;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["node"] = node;
			args["imagename"] = imagename;
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