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

package com.flack.geni.tasks.tests
{
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.GetUserCredentialSaTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.GetUserKeysSaTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.RegisterSliceSaTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.RenewSliceSaTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.ResolveSliceSaTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.ResolveUserSaTask;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskEvent;
	
	public class AuthorityTestGroup extends TestTaskGroup
	{
		private var authority:GeniAuthority;
		public function AuthorityTestGroup(testAuthority:GeniAuthority)
		{
			super(
				"Test authority functions",
				"Test authority functions"
			);
		}
		
		override protected function startTest():void
		{
			addTest(
				"Get user credential",
				new GetUserCredentialSaTask(S, authority),
				gotCredential
			);
		}
		
		public function gotCredential(event:TaskEvent):void
		{
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed("Status != Success");
			else
			{
				testSucceeded();
				
				addTest(
					"Submit slice",
					new ResolveUserSaTask(),
					resolvedUser
				);
			}
		}
		
		public function resolvedUser(event:TaskEvent):void
		{
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed("Status != Success");
			else
			{
				testSucceeded();
				
				addTest(
					"Submit slice",
					new GetUserKeysSaTask(),
					gotKeys
				);
			}
		}
		
		public function gotKeys(event:TaskEvent):void
		{
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed("Status != Success");
			else
			{
				testSucceeded();
				
				addTest(
					"Submit slice",
					new RegisterSliceSaTask(),
					registeredSlice
				);
			}
		}
		
		public function registeredSlice(event:TaskEvent):void
		{
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed("Status != Success");
			else
			{
				testSucceeded();
				
				addTest(
					"Submit slice",
					new ResolveSliceSaTask(),
					resolvedSlice
				);
			}
		}
		
		public function resolvedSlice(event:TaskEvent):void
		{
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed("Status != Success");
			else
			{
				testSucceeded();
				
				addTest(
					"Submit slice",
					new RenewSliceSaTask(),
					renewedSlice
				);
			}
		}
		
		public function renewedSlice(event:TaskEvent):void
		{
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed("Status != Success");
			else
			{
				testSucceeded();
				testsSucceeded();
			}
		}
	}
}