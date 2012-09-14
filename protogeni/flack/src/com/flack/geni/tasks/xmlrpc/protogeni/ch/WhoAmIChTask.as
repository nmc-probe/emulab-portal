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

package com.flack.geni.tasks.xmlrpc.protogeni.ch
{
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	
	/**
	 * Gets the user's ID and slice authority
	 * 
	 * @author mstrum
	 * 
	 */
	public final class WhoAmIChTask extends ProtogeniXmlrpcTask
	{
		public var user:GeniUser;
		
		/**
		 * 
		 * @param taskUser User we are looking up
		 * 
		 */
		public function WhoAmIChTask(taskUser:GeniUser)
		{
			super(
				GeniMain.geniUniverse.clearinghouse.url,
				ProtogeniXmlrpcTask.MODULE_CH,
				ProtogeniXmlrpcTask.METHOD_WHOAMI,
				"Look me up",
				"Returns information about who I am using the SSL certificate");
			relatedTo.push(taskUser);
			user = taskUser;
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if(code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				user.id = new IdnUrn(data.urn);
				var authorityId:String = data.sa_urn;
				for each(var sa:GeniAuthority in GeniMain.geniUniverse.authorities.collection)
				{
					if(sa.id.full == authorityId)
					{
						user.authority = sa;
						break;
					}
				}
				
				if(user.authority == null)
				{
					// XXX afterError? Make sure this doesn't break non-ProtoGENI users
					addMessage(
						"Authority not found",
						authorityId,
						LogMessage.LEVEL_WARNING,
						LogMessage.IMPORTANCE_HIGH
					);
				}
				else
				{
					addMessage(
						"Authority found",
						user.toString(),
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
				}
				
				SharedMain.sharedDispatcher.dispatchChanged(
					FlackEvent.CHANGED_USER,
					user
				);
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}