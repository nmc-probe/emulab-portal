/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

package com.flack.emulab.tasks.xmlrpc.osid
{
	import com.flack.emulab.EmulabMain;
	import com.flack.emulab.resources.physical.Osid;
	import com.flack.emulab.resources.physical.OsidCollection;
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.core.FlexGlobals;
	
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
		
		private var myIndex:int;
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				EmulabMain.manager.osids = new OsidCollection();
				for(var osidString:String in data)
				{
					var osidObject:Object = data[osidString];
					var newOsid:Osid = new Osid(
						osidString,
						osidObject.OS,
						osidObject.version,
						osidObject.description,
						osidObject.pid,
						osidObject.creator,
						osidObject.created
					);
					EmulabMain.manager.osids.add(newOsid);
				}
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}