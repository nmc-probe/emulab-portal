package com.flack.emulab.tasks.xmlrpc.osid
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabOsidGetListTask extends EmulabXmlrpcTask
	{
		public function EmulabOsidGetListTask()
		{
			super(
				EmulabMain.manager.api.url,
				EmulabXmlrpcTask.MODULE_OSID,
				EmulabXmlrpcTask.METHOD_GETLIST,
				"Get OSID List @ " + EmulabMain.manager.api.url,
				"Getting OSID list on manager at " + EmulabMain.manager.api.url,
				"Get OSID List"
			);
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				// the return value is a hash table containing the OS IDs and their descriptions.
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}