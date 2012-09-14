/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group,
* University of Kentucky and the Laboratory for Advanced Networking.
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

package com.flack.geni.plugins.instools.instasks
{
	import com.flack.geni.plugins.instools.SliceInstoolsDetails;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.GenerateRequestManifestTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.tasks.ParallelTaskGroup;
	
	import flash.display.Sprite;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	/**
	 * Polls all of the slivers for INSTOOLS status and makes sure everyone is instrumentized
	 * 
	 * @author mstrum
	 * 
	 */
	public class SaveManifestTaskGroup extends ParallelTaskGroup
	{
		public var details:SliceInstoolsDetails;
		public function SaveManifestTaskGroup(useDetails:SliceInstoolsDetails)
		{
			super(
				"Saving Manifest",
				"Sends the combined manifest to each CMs."
			);
			relatedTo.push(useDetails.slice);
			details = useDetails;
			
			var generate:GenerateRequestManifestTask = new GenerateRequestManifestTask(details.slice, true, true);
			generate.start();
			
			for each(var sliver:Sliver in details.slice.slivers.collection)
			{
				if(details.MC_present[sliver.manager.id.full])
					add(new SaveManifestTask(sliver, details, generate.resultRspec));
				else
				{
					addMessage(
						"Skipping " + sliver.manager.hrn,
						"Did not send manifest to " + sliver.manager.hrn + " because INSTOOLS was not detected there"
					);
				}
			}
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=true):void
		{
			super.afterComplete(addCompletedMessage);
		}
	}
}