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
	import com.flack.geni.GeniMain;
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.utils.NetUtil;
	
	import flash.display.Sprite;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	/**
	 * Gets the user's public SSH keys
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetUserKeysSaTask extends ProtogeniXmlrpcTask
	{
		public var user:GeniUser;
		public var replaceAll:Boolean;
		
		/**
		 * 
		 * @param newUser User to get keys for
		 * @param shouldReplaceAll Replace the old keys with these, removing any which aren't returned in this call
		 * 
		 */
		public function GetUserKeysSaTask(newUser:GeniUser,
										  shouldReplaceAll:Boolean = true)
		{
			super(
				newUser.authority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_GETKEYS,
				"Get SSH keys",
				"Gets user's public keys"
			);
			relatedTo.push(newUser);
			user = newUser;
			replaceAll = shouldReplaceAll;
		}
		
		override protected function createFields():void
		{
			addNamedField("credential", user.credential.Raw);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == CODE_SUCCESS)
			{
				if(replaceAll)
					user.keys = new Vector.<String>();
				for each(var keyObject:Object in data)
				{
					if(user.keys.indexOf(keyObject.key) == -1)
					{
						addMessage("Public key retrieved", keyObject.key);
						user.keys.push(keyObject.key);
					}
				}
				
				addMessage(
					user.keys.length + " public key(s) retrieved",
					user.keys.length + " public key(s) retrieved",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				if(user.keys.length == 0)
				{
					Alert.show(
						"You don't have any SSH keys, which are required to log into resources.  View online instructions for setting up your SSH keys?",
						"", Alert.YES|Alert.NO, FlexGlobals.topLevelApplication as Sprite,
						function visitSite(e:CloseEvent):void
						{
							if(e.detail == Alert.YES)
								NetUtil.openWebsite(GeniMain.sshKeysSteps);
						}
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