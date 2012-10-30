/*
 * Copyright (c) 2008-2012 University of Utah and the Flux Group.
 * 
 * {{{GENIPUBLIC-LICENSE
 * 
 * GENI Public License
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and/or hardware specification (the "Work") to
 * deal in the Work without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Work, and to permit persons to whom the Work
 * is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Work.
 * 
 * THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
 * IN THE WORK.
 * 
 * }}}
 */

package com.flack.geni.tasks.xmlrpc.am
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Deallocates all resources in the sliver.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class DeleteTask extends AmXmlrpcTask
	{
		public var sliver:Sliver;
		/**
		 * 
		 * @param deleteSliver Sliver for which to deallocate resources in
		 * 
		 */
		public function DeleteTask(deleteSliver:Sliver)
		{
			super(
				deleteSliver.manager.api.url,
				deleteSliver.manager.api.version < 3
					? AmXmlrpcTask.METHOD_DELETESLIVER : AmXmlrpcTask.METHOD_DELETE,
				deleteSliver.manager.api.version,
				"Delete @ " + deleteSliver.manager.hrn,
				"Deleting on aggregate manager " + deleteSliver.manager.hrn + " for slice named " + deleteSliver.slice.Name,
				"Delete"
			);
			relatedTo.push(deleteSliver);
			relatedTo.push(deleteSliver.slice);
			relatedTo.push(deleteSliver.manager);
			sliver = deleteSliver;
		}
		
		override protected function createFields():void
		{
			addOrderedField(sliver.slice.id.full);
			addOrderedField([sliver.slice.credential.Raw]);
			if(apiVersion > 1)
				addOrderedField({});
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Sanity check for AM API 2+
			if(apiVersion > 1)
			{
				if(genicode != AmXmlrpcTask.GENICODE_SUCCESS && genicode != AmXmlrpcTask.GENICODE_SEARCHFAILED)
				{
					faultOnSuccess();
					return;
				}
			}
			
			try
			{
				if(data == true || data == 1)
				{
					sliver.manifest = null;
					sliver.removeFromSlice();
					//sliver.UnsubmittedChanges = false;
					
					addMessage(
						"Removed",
						"Slice successfully removed",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLIVER,
						sliver,
						FlackEvent.ACTION_REMOVED
					);
					SharedMain.sharedDispatcher.dispatchChanged(
						FlackEvent.CHANGED_SLICE,
						sliver.slice,
						FlackEvent.ACTION_REMOVING
					);
					
					super.afterComplete(addCompletedMessage);
				}
				else if(data == false || data == 0)
				{
					afterError(
						new TaskError(
							"Received false when trying to delete sliver on " + sliver.manager.hrn + ".",
							TaskError.CODE_PROBLEM
						)
					);
				}
				else
					throw new Error("Invalid data received");
			}
			catch(e:Error)
			{
				afterError(
					new TaskError(
						StringUtil.errorToString(e),
						TaskError.CODE_UNEXPECTED,
						e
					)
				);
			}
		}
	}
}