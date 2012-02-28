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
	import com.flack.geni.resources.sites.GeniAuthority;
	import com.flack.geni.resources.sites.authorities.ProtogeniSliceAuthority;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.tasks.SerialTaskGroup;
	
	/**
	 * Gets user information, like name, email, list of slices, public keys, subauthorities, etc.
	 * 
	 * @author mstrum
	 * 
	 */
	public class ResolveUserSaTask extends ProtogeniXmlrpcTask
	{
		public var user:GeniUser;
		public var authority:GeniAuthority;
		
		/**
		 * 
		 * @param newUser User to resolve
		 * @param newAuthority Authority to resolve at
		 * 
		 */
		public function ResolveUserSaTask(newUser:GeniUser,
										  newAuthority:GeniAuthority)
		{
			super(
				newAuthority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_RESOLVE,
				"Resolve user",
				"Resolves the user"
			);
			authority = newAuthority;
			relatedTo.push(newUser);
			user = newUser;
		}
		
		override protected function createFields():void
		{
			addNamedField("type", "User");
			addNamedField("credential", authority.userCredential.Raw);
			addNamedField("hrn", GeniMain.geniUniverse.user.id.full);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				user.uid = data.uid;
				user.hrn = data.hrn;
				user.email = data.email;
				user.name = data.name;
				
				// Remove slices from the authority being resolved
				for(var i:int = 0; i < user.slices.length; i++)
				{
					if(user.slices.collection[i].authority.id.full == authority.id.full)
					{
						user.slices.remove(user.slices.collection[i]);
						i--;
					}
				}
				
				// Add slices
				var slices:Array = data.slices;
				if(slices != null && slices.length > 0)
				{
					for each(var sliceUrn:String in slices)
					{
						var userSlice:Slice = new Slice();
						userSlice.id = new IdnUrn(sliceUrn);
						if(userSlice.id.authority != authority.id.authority)
							continue;
						userSlice.creator = user;
						userSlice.authority = authority;
						user.slices.add(userSlice);
						SharedMain.sharedDispatcher.dispatchChanged(
							FlackEvent.CHANGED_SLICE,
							userSlice, FlackEvent.ACTION_CREATED
						);
						SharedMain.sharedDispatcher.dispatchChanged(
							FlackEvent.CHANGED_SLICES,
							userSlice,
							FlackEvent.ACTION_ADDED
						);
					}
				}
				
				if(data.pubkeys != null)
				{
					for each(var pubkey:Object in data.pubkeys)
					{
						if(user.keys.indexOf(pubkey.key) == -1)
							user.keys.push(pubkey.key);
					}
				}
				
				// Add authorities which haven't been added yet
				if(data.subauthorities != null)
				{
					for(var saId:String in data.subauthorities)
					{
						var saUrl:String = data.subauthorities[saId];
						if(user.subAuthorities.getById(saId) == null)
						{
							var newAuthority:ProtogeniSliceAuthority = new ProtogeniSliceAuthority(saId, saUrl, false, user.authority as ProtogeniSliceAuthority);
							user.subAuthorities.add(newAuthority);
							var resolveUserAtSubauthority:SerialTaskGroup = new SerialTaskGroup("Resolve " + user.name + " @ " + newAuthority.name, "Resolves the user at a sub-authority");
							resolveUserAtSubauthority.add(new GetUserCredentialSaTask(user, newAuthority));
							resolveUserAtSubauthority.add(new ResolveUserSaTask(user, newAuthority));
							parent.add(resolveUserAtSubauthority);
						}
					}
				}
				
				addMessage(
					"Resolved " + user.uid,
					"Resolved and got all information for user " + user.uid,
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