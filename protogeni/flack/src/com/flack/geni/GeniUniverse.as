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

package com.flack.geni
{
	import com.flack.geni.display.windows.LoginWindow;
	import com.flack.geni.resources.GeniUser;
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.resources.sites.GeniAuthorityCollection;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.sites.clearinghouses.ProtogeniClearinghouse;
	import com.flack.geni.tasks.groups.GetPublicResourcesTaskGroup;
	import com.flack.geni.tasks.groups.GetResourcesTaskGroup;
	import com.flack.geni.tasks.groups.GetUserTaskGroup;
	import com.flack.geni.tasks.groups.InitializeUserTaskGroup;
	import com.flack.shared.SharedMain;

	/**
	 * Holds all of the things we care about, GeniMain holds a globally static instance of this.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class GeniUniverse
	{
		public var managers:GeniManagerCollection;
		public function get user():GeniUser
		{
			return SharedMain.user as GeniUser;
		}
		public var authorities:GeniAuthorityCollection;
		public var clearinghouse:ProtogeniClearinghouse;
		
		public function GeniUniverse()
		{
			managers = new GeniManagerCollection();
			SharedMain.user = new GeniUser();
			authorities = new GeniAuthorityCollection();
			clearinghouse = new ProtogeniClearinghouse();
		}
		
		public function loadPublic():void
		{
			SharedMain.tasker.add(new GetPublicResourcesTaskGroup());
		}
		
		public function login():void
		{
			var loginWindow:LoginWindow = new LoginWindow();
			loginWindow.showWindow(true);
		}
		
		public function loadAuthenticated():void
		{
			// User is authenticated and either has a credential or an authority assigned to them
			if(user.CertificateSetUp)
			{
				// XXX other frameworks
				// Get user credential + key if they have an authority
				if(user.authority == null || user.authority.type != GeniAuthority.TYPE_EMULAB)
					SharedMain.tasker.add(new InitializeUserTaskGroup(user, true));
				
				SharedMain.tasker.add(new GetResourcesTaskGroup(managers.length == 0));
				
				SharedMain.tasker.add(
					new GetUserTaskGroup(
						user,
						GeniMain.geniUniverse.user.authority != null,
						true
					)
				);
			}
			// Needs to authenticate
			else
				login();
		}
	}
}