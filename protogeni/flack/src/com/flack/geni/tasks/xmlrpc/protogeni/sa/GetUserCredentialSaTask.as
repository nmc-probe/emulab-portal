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

package com.flack.geni.tasks.xmlrpc.protogeni.sa
{
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	
	/**
	 * Gets the user's credential.
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetUserCredentialSaTask extends ProtogeniXmlrpcTask
	{
		public var user:GeniUser;
		public var authority:GeniAuthority;
		
		/**
		 * 
		 * @param newUser User for which we are getting the credential for
		 * @param newAuthority Authority where we want to get the credential from
		 * 
		 */
		public function GetUserCredentialSaTask(newUser:GeniUser, newAuthority:GeniAuthority)
		{
			super(
				newAuthority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_GETCREDENTIAL,
				"Get user credential",
				"Gets the user's credential to perform authenticated actions with"
			);
			authority = newAuthority;
			relatedTo.push(newUser);
			user = newUser;
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == CODE_SUCCESS)
			{
				var userCredential:GeniCredential = new GeniCredential(String(data), GeniCredential.TYPE_USER, user.authority);
				if(user.authority == authority)
				{
					user.credential = userCredential;
					user.id = user.credential.OwnerId;
				}
				authority.userCredential = userCredential;
				
				addMessage(
					"Retrieved",
					userCredential.Raw,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
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