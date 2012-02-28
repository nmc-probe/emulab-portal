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

package com.flack.geni.tasks.groups.slice
{
	import com.flack.geni.resources.sites.GeniManager;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.tasks.process.StartImportSliceTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.SerialTaskGroup;
	
	/**
	 * Imports a given RSPEC into the slice.
	 * 
	 * 1. Runs a StartImport task to do preliminary checks
	 * 2. Runs Parse tasks at all slivers
	 * 
	 * @author mstrum
	 * 
	 */
	public final class ImportSliceTaskGroup extends SerialTaskGroup
	{
		public var slice:Slice;
		public var rspecString:String;
		public var manager:GeniManager;
		public var overwrite:Boolean;
		
		/**
		 * 
		 * @param importSlice Slice to import RSPEC into
		 * @param importRspec RSPEC to import into slice
		 * @param importManager Manager to default to if not listed
		 * @param allowOverwrite Allow the import to happen into an allocated slice
		 * 
		 */
		public function ImportSliceTaskGroup(importSlice:Slice,
											 importRspec:String,
											 importManager:GeniManager = null,
											 allowOverwrite:Boolean = false)
		{
			super(
				"Import slice",
				"Imports the given RSPEC into the slice"
			);
			relatedTo.push(importSlice);
			slice = importSlice;
			rspecString = importRspec;
			manager = importManager;
			overwrite = allowOverwrite;
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
				add(
					new StartImportSliceTask(
						slice,
						rspecString,
						manager,
						overwrite
					)
				);
			else
				super.runStart();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Remove slivers we don't care about
			for(var i:int = 0; i < slice.slivers.length; i++)
			{
				if(!slice.slivers.collection[i].Created && slice.slivers.collection[i].Nodes.length == 0)
				{
					slice.slivers.collection[i].removeFromSlice();
					i--;
				}
			}
			
			addMessage(
				"Finished",
				slice.toString(),
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
			SharedMain.sharedDispatcher.dispatchChanged(
				FlackEvent.CHANGED_SLICE,
				slice,
				FlackEvent.ACTION_POPULATED
			);
			
			super.afterComplete(addCompletedMessage);
		}
	}
}