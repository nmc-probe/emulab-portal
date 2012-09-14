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
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.display.components.TextInputWindow;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.tasks.TaskError;

	/**
	 * If creating, used to check to make sure slice name is valid and not used.
	 * If getting, gets basic information like what managers have slivers.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class ResolveSliceSaTask extends ProtogeniXmlrpcTask
	{
		public var slice:Slice;
		public var isCreating:Boolean;
		public var prompt:Boolean;
		
		/**
		 * 
		 * @param taskSlice Slice to resolve
		 * @param creating Resolving before creating? FALSE if getting.
		 * @param promptUserForName Prompt the user if a different slice name is needed
		 * 
		 */
		public function ResolveSliceSaTask(taskSlice:Slice,
										   creating:Boolean = false,
										   promptUserForName:Boolean = false)
		{
			super(
				taskSlice.authority.url,
				"",
				ProtogeniXmlrpcTask.METHOD_RESOLVE,
				"Resolve " + taskSlice.Name,
				"Resolving slice named " + taskSlice.Name,
				"Resolve Slice"
			);
			relatedTo.push(taskSlice);
			slice = taskSlice;
			isCreating = creating;
			prompt = promptUserForName;
		}
		
		override protected function runStart():void
		{
			if(prompt)
				promptName();
			else
				super.runStart();
		}
		
		public function promptName():void
		{
			var promptForNameWindow:TextInputWindow = new TextInputWindow();
			promptForNameWindow.onSuccess = userChoseName;
			promptForNameWindow.onCancel = cancel;
			promptForNameWindow.showWindow();
			promptForNameWindow.valueTextinput.restrict = "a-zA-Z0-9\-";
			promptForNameWindow.valueTextinput.maxChars = 19;
			if(slice.Name.length > 0)
				promptForNameWindow.title = "Slice name not valid, please try another";
			else
				promptForNameWindow.title = "Please enter a valid, non-existing slice name";
			promptForNameWindow.Text = slice.Name;
		}
		
		public function userChoseName(newName:String):void
		{
			slice.id = IdnUrn.makeFrom(slice.authority.id.authority, IdnUrn.TYPE_SLICE, newName);
			super.runStart();
		}
		
		override protected function createFields():void
		{
			addNamedField("credential", slice.authority.userCredential.Raw);
			addNamedField("urn", slice.id.full);
			addNamedField("type", "Slice");
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			var msg:String;
			if(isCreating)
			{
				if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
				{
					afterError(
						new TaskError(
							"Already exists. Slice named " + slice.Name + " already exists",
							TaskError.CODE_PROBLEM,
							code
						)
					);
				}
				else if(code == ProtogeniXmlrpcTask.CODE_SEARCHFAILED)
				{
					// Good, the slice doesn't exist, run remove before creating
					parent.add(new RemoveSliceSaTask(slice));
					
					addMessage(
						"Valid",
						"No other slice has the same name. Slice can be created.",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					super.afterComplete(addCompletedMessage);
				}
				// Bad name
				else if(code == ProtogeniXmlrpcTask.CODE_BADARGS)
				{
					afterError(
						new TaskError(
							"Bad name. Slice creation failed because of a bad name: " + slice.Name,
							TaskError.CODE_PROBLEM,
							code
						)
					);
				}
				else if(code == ProtogeniXmlrpcTask.CODE_FORBIDDEN)
				{
					afterError(
						new TaskError(
							"Forbidden. " + output,
							TaskError.CODE_PROBLEM,
							code
						)
					);
				}
				else
					faultOnSuccess();
			}
			// Getting
			else
			{
				if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
				{
					slice.id = new IdnUrn(data.urn);
					slice.hrn = data.hrn;
					slice.reportedManagers = new GeniManagerCollection();
					for each(var reportedManagerId:String in data.component_managers)
					{
						var manager:GeniManager = GeniMain.geniUniverse.managers.getById(reportedManagerId);
						if(manager != null)
							slice.reportedManagers.add(manager);
					}
					
					addMessage(
						"Resolved",
						slice.Name + " was found with slivers on " + slice.reportedManagers.length + " known manager(s)",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLICE,
						slice
					);
					
					super.afterComplete(addCompletedMessage);
				}
				else
					faultOnSuccess();
			}
		}
	}
}