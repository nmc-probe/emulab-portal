package com.flack.emulab.tasks.xmlrpc.node
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabNodeReloadTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		// required
		private var nodes:Vector.<String>;
		// optional
		private var imagename:String;
		private var imageproj:String;
		private var imageid:String;
		private var reboot:Boolean;
		public function EmulabNodeReloadTask(newNodes:Vector.<String>, newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_NODE,
				EmulabXmlrpcTask.METHOD_RELOAD,
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