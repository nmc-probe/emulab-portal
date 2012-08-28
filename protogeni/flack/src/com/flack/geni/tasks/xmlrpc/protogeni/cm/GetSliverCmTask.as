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
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.DateUtil;
	
	/**
	 * Gets the sliver credential and adds a resolve call to get the manifest to the parent task.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GetSliverCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		
		/**
		 * 
		 * @param newSliver Sliver to get
		 * 
		 */
		public function GetSliverCmTask(newSliver:Sliver)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_GETSLIVER,
				"Get sliver @ " + newSliver.manager.hrn,
				"Gets the sliver credential for component manager named " + newSliver.manager.hrn,
				"Get Sliver"
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
				sliver.credential =
					new GeniCredential(
						String(data),
						GeniCredential.TYPE_SLIVER,
						sliver.manager
					);
				sliver.id = sliver.credential.TargetId;
				sliver.expires = sliver.credential.Expires;
				
				addMessage(
					"Credential received",
					sliver.credential.Raw,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Expires in " + DateUtil.getTimeUntil(sliver.expires),
					"Expires in " + DateUtil.getTimeUntil(sliver.expires),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				parent.add(new ResolveSliverCmTask(sliver));
				
				super.afterComplete(addCompletedMessage);
			}
 			else if(
				code == ProtogeniXmlrpcTask.CODE_SEARCHFAILED ||
				code == ProtogeniXmlrpcTask.CODE_BADARGS)
			{
				addMessage(
					"No sliver",
					"No sliver found here",
					LogMessage.LEVEL_WARNING,
					LogMessage.IMPORTANCE_HIGH
				);
				super.afterComplete(true);
			}
			else
				faultOnSuccess();
		}
		
		override protected function afterError(taskError:TaskError):void
		{
			sliver.status = Sliver.STATUS_FAILED;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLIVER,
				sliver,
				FlackEvent.ACTION_STATUS
			);
			
			super.afterError(taskError);
		}
		
		override protected function runCancel():void
		{
			sliver.status = Sliver.STATUS_UNKNOWN;
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLIVER,
				sliver,
				FlackEvent.ACTION_STATUS
			);
		}
	}
}