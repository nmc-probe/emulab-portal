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
	import com.flack.geni.tasks.xmlrpc.am.RenewSliverTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.cm.RenewSliverCmTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.sa.RenewSliceSaTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.sites.ApiDetails;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.utils.DateUtil;
	
	/**
	 * Renews the slice and all slivers to the given date
	 * 
	 * @author mstrum
	 * 
	 */
	public final class RenewSliceTaskGroup extends ParallelTaskGroup
	{
		public var slice:Slice;
		public var expires:Date;
		
		/**
		 * 
		 * @param renewSlice Slice (and child slivers) to be renewed
		 * @param newExpiresDate Date to renew all resources to
		 * 
		 */
		public function RenewSliceTaskGroup(renewSlice:Slice,
											newExpiresDate:Date)
		{
			super(
				"Renew " + renewSlice.Name,
				"Renews the slice named " + renewSlice.Name + " until " + DateUtil.getTimeUntil(newExpiresDate) + " from now."
			);
			slice = renewSlice;
			expires = newExpiresDate;
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
			{
				if(slice.expires != null && expires.time < slice.expires.time)
				{
					addMessage(
						"Only sliver need renewing",
						"Slice will expire after the new expires time, renewing slivers",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
					renewSlivers();
				}
				else if(slice.creator.authority != null)
					add(new RenewSliceSaTask(slice, expires));
			}
			super.runStart();
		}
		
		override public function completedTask(task:Task):void
		{
			if(task is RenewSliceSaTask)
				renewSlivers();
			super.completedTask(task);
		}
		
		private function renewSlivers():void
		{
			for each(var sliver:Sliver in slice.slivers.collection)
			{
				if(sliver.expires == null || sliver.expires.time < expires.time)
				{
					if(sliver.manager.api.type == ApiDetails.API_GENIAM)
						add(new RenewSliverTask(sliver, expires));
					else
						add(new RenewSliverCmTask(sliver, expires));
				}
				else
				{
					addMessage(
						"Sliver on "+sliver.manager.hrn+" expires later",
						"Sliver on "+sliver.manager.hrn+" expires later and doesn't need to be renewed",
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
				}
			}
		}
		
		override public function erroredTask(task:Task):void
		{
			afterError(task.error);
			cancelRemainingTasks();
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			var earliestSliverExpiration:Date = slice.slivers.EarliestExpiration;
			if(earliestSliverExpiration < slice.expires)
			{
				addMessage(
					"Renewed. Slivers expire before slice in "+DateUtil.getTimeUntil(earliestSliverExpiration) +".",
					"Slivers will start to expire in " + DateUtil.getTimeUntil(earliestSliverExpiration) + ". The slice will expire in " + DateUtil.getTimeUntil(slice.expires) + ".",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
			}
			else
			{
				addMessage(
					"Renewed. All expire at the same time in "+DateUtil.getTimeUntil(slice.expires)+".",
					"Slivers and slice will start to expire in " + DateUtil.getTimeUntil(slice.expires) + ".",
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
			}
			super.afterComplete(addCompletedMessage);
		}
	}
}