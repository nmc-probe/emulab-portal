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

package com.flack.geni.tasks.xmlrpc.protogeni.cm
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
	
	/**
	 * Restarts all resources in the sliver
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RestartSliverCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		
		/**
		 * 
		 * @param newSliver Sliver to restart resources for
		 * 
		 */
		public function RestartSliverCmTask(newSliver:Sliver)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_RESTARTSLIVER,
				"Restart sliver @ " + newSliver.manager.hrn,
				"Restarts sliver on " + newSliver.manager.hrn + " for slice named " + newSliver.slice.Name,
				"Restart Sliver"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			sliver = newSliver;
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sliver.slice.id.full);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				addMessage(
					"Restarted",
					"Sliver was restarted",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}