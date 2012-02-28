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

package com.flack.geni.tasks.groups
{
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.tasks.xmlrpc.protogeni.ch.WhoAmIChTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.GetUserCredentialSaTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.GetUserKeysSaTask;
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	
	/**
	 * Gets the user credential and ssh keys. Detects user authority if not set.
	 * 
	 * 1. If no authority assigned: WhoAmIChTask
	 * 2. If no user credential or replaceOldInformation:
	 *  2a. GetUserCredentialSaTask
	 *  2b. GetUserKeysSaTask
	 * 
	 * @author mstrum
	 * 
	 */
	public class InitializeUserTaskGroup extends SerialTaskGroup
	{
		public var user:GeniUser;
		public var replaceOldInformation:Boolean;
		
		/**
		 * 
		 * @param taskUser User to initialize
		 * @param taskReplaceOldInformation Replace keys and credential?
		 * 
		 */
		public function InitializeUserTaskGroup(taskUser:GeniUser,
												taskReplaceOldInformation:Boolean = false)
		{
			super(
				"Initialize user",
				"Gets initial info about the user"
			);
			relatedTo.push(taskUser);
			forceSerial = true;
			
			user = taskUser;
			replaceOldInformation = taskReplaceOldInformation;
		}
		
		override protected function runStart():void
		{
			// First run
			if(tasks.length == 0)
			{
				if(user.authority == null)
					add(new WhoAmIChTask(user)); // XXX see what happens with a pl user...
				else
					getUser();
			}
			super.runStart();
		}
		
		override public function completedTask(task:Task):void
		{
			if(task is WhoAmIChTask)
				getUser();
			super.completedTask(task);
		}
		
		public function getUser():void
		{
			if(user.authority != null && (user.credential == null || replaceOldInformation))
			{
				add(new GetUserCredentialSaTask(user, user.authority));
				add(new GetUserKeysSaTask(user));
			}
			else
				afterComplete();
		}
	}
}