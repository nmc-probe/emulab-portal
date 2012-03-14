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

package com.flack.geni.tasks.xmlrpc.am
{
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.CompressUtil;
	import com.flack.shared.utils.StringUtil;
	
	/**
	 * Lists the sliver's resources at the manager.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class ListSliverResourcesTask extends AmXmlrpcTask
	{
		public var sliver:Sliver;
		
		/**
		 * 
		 * @param newSliver Sliver for which to list resources allocated to the sliver's slice
		 * 
		 */
		public function ListSliverResourcesTask(newSliver:Sliver)
		{
			super(
				newSliver.manager.api.url,
				AmXmlrpcTask.METHOD_LISTRESOURCES,
				newSliver.manager.api.version,
				"List sliver resources @ " + newSliver.manager.hrn,
				"Listing sliver resources for aggregate manager " + newSliver.manager.hrn,
				"List Sliver Resources"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			sliver = newSliver;
		}
		
		override protected function createFields():void
		{
			addOrderedField([sliver.slice.credential.Raw]);
			
			var options:Object = 
				{
					geni_available: false,
					geni_compressed: true,
					geni_slice_urn: sliver.slice.id.full
				};
			var rspecVersion:Object = 
				{
					type: sliver.slice.useInputRspecInfo.type,
					version: sliver.slice.useInputRspecInfo.version.toString()
				};
			if(apiVersion < 2)
				options.rspec_version = rspecVersion;
			else
				options.geni_rspec_version = rspecVersion;
			
			addOrderedField(options);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Sanity check for AM API 2+
			if(apiVersion > 1)
			{
				if(genicode == AmXmlrpcTask.GENICODE_SEARCHFAILED || genicode == AmXmlrpcTask.GENICODE_BADARGS)
				{
					addMessage(
						"No sliver",
						"No sliver found here",
						LogMessage.LEVEL_WARNING,
						LogMessage.IMPORTANCE_HIGH
					);
					super.afterComplete(true);
				}
				else if(genicode != AmXmlrpcTask.GENICODE_SUCCESS)
				{
					faultOnSuccess();
					return;
				}
			}
			
			try
			{
				var uncompressedRspec:String = CompressUtil.uncompress(data);
				
				addMessage(
					"Manifest received",
					uncompressedRspec,
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				sliver.manifest = new Rspec(uncompressedRspec,null,null,null, Rspec.TYPE_MANIFEST);
				parent.add(new ParseRequestManifestTask(sliver, sliver.manifest, false, true));
				
				super.afterComplete(addCompletedMessage);
				
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