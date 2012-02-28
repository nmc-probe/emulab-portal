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
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.SerialTaskGroup;
	
	import flash.utils.Dictionary;
	
	/**
	 * Clears the slice and reloads based on the previouslly retrieved manifests.
	 * If changes are made to a slice which need to be undone, call this.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RevertToManifestsTaskGroup extends SerialTaskGroup
	{
		public var idToStatus:Dictionary;
		public var idToState:Dictionary;
		public var slice:Slice;
		/**
		 * 
		 * @param newSlice Slice to revert back to the last allocated state
		 * 
		 */
		public function RevertToManifestsTaskGroup(newSlice:Slice)
		{
			super(
				"Revert to manifests",
				"Reverts the slice to the recieved manifests"
			);
			slice = newSlice;
			
			slice.removeComponents();
			slice.clearStatus();
			for(var i:int = 0; i < slice.slivers.length; i++)
			{
				var sliver:Sliver = slice.slivers.collection[i];
				if(sliver.Created)
					add(new ParseRequestManifestTask(sliver, sliver.manifest));
				else
				{
					slice.slivers.remove(sliver);
					i--;
				}
			}
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			// Try to revert if there's anything to revert
			slice.resetStatus();
			
			addMessage(
				"Reverted",
				slice.Name + " has been reverted to its state when it was created. ",
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