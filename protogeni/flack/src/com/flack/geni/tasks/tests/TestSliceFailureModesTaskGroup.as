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
	import com.flack.geni.GeniMain;
	import com.flack.geni.plugins.emulab.RawPcSliverType;
	import com.flack.geni.resources.SliverTypes;
	import com.flack.geni.resources.sites.managers.ProtogeniComponentManager;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.tasks.groups.slice.CreateSliceTaskGroup;
	import com.flack.geni.tasks.groups.slice.DeleteSliversTaskGroup;
	import com.flack.geni.tasks.groups.slice.SubmitSliceTaskGroup;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.resources.sites.FlackManager;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskEvent;
	
	/**
	 * Runs a series of tests to see if the code for working with slices is correct
	 * 
	 * 1. Fail at creating a slice with a bad name (give a good name)
	 * 2. Fail at submitting to a non-existant CM first
	 * 3. Fail at submitting to a non-existant CM second
	 * 
	 * @author mstrum
	 * 
	 */
	public final class TestSliceFailureModesTaskGroup extends TestTaskGroup
	{
		public var badManager:ProtogeniComponentManager;
		
		public function TestSliceFailureModesTaskGroup()
		{
			super(
				"Test failed slice ops",
				"Tests to make sure all code dealing with failures in slices is correct"
			);
			
			badManager = new ProtogeniComponentManager(IdnUrn.makeFrom("badmanager.com", IdnUrn.TYPE_AUTHORITY, "cm").full);
			badManager.url = "https://www.google.com";
			badManager.inputRspecVersion = GeniMain.usableRspecVersions.MaxVersion;
			badManager.Status = FlackManager.STATUS_VALID;
			badManager.hrn = "badmanager.cm";
		}
		
		// Try to create a slice with a bad name, let user choose good name
		override protected function startTest():void
		{
			addTest(
				"Bad slice name",
				new CreateSliceTaskGroup(
					"!@#$%^&!!!CHANGEME!!!*()-_=+",
					GeniMain.geniUniverse.user.authority
				), 
				firstMisnamedSliceFailed
			);
		}
		
		// Try to create slice with a bad sliver first, cancel remaining
		public function firstMisnamedSliceFailed(event:TaskEvent):void
		{
			var slice:Slice = (event.task as CreateSliceTaskGroup).newSlice;
			
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed();
			else
			{
				testSucceeded();
				
				addMessage(
					"Preparing Step #" + NextStepNumber,
					"Preparing slice with bad sliver first"
				);
				
				var newGoodNode:VirtualNode = new VirtualNode(
					slice,
					GeniMain.geniUniverse.managers.getByHrn("utahemulab.cm"),
					"goodNode",
					true,
					RawPcSliverType.TYPE_RAWPC_V2
				);
				
				var newBadNode:VirtualNode = new VirtualNode(
					slice,
					badManager,
					"badNode",
					true,
					RawPcSliverType.TYPE_RAWPC_V2
				);
				
				// Order matters, slivers are created in the order they are added
				slice.slivers.add(new Sliver(slice, newBadNode.manager));
				slice.slivers.add(new Sliver(slice, newGoodNode.manager));
				slice.nodes.add(newGoodNode);
				slice.nodes.add(newBadNode);
				
				addTest(
					"Submit slice",
					new SubmitSliceTaskGroup(slice, false), 
					firstSliceCanceled
				);
			}
		}
		
		// Create slice with a bad second sliver
		public function firstSliceCanceled(event:TaskEvent):void
		{
			var slice:Slice = (event.task as SubmitSliceTaskGroup).slice;
			
			if(event.task.Status != Task.STATUS_CANCELED)
				testFailed();
			else
			{
				testSucceeded();
				
				addMessage(
					"Preparing Step #" + NextStepNumber,
					"Preparing slice with bad sliver second"
				);
				
				slice.slivers.collection = slice.slivers.collection.reverse();
				
				addTest(
					"Submit slice with a bad sliver first and good second",
					new SubmitSliceTaskGroup(slice, false), 
					firstSliceHalfCreated
				);
			}
		}
		
		public function firstSliceHalfCreated(event:TaskEvent):void
		{
			var slice:Slice = (event.task as SubmitSliceTaskGroup).slice;
			
			if(event.task.Status == Task.STATUS_SUCCESS)
				testFailed();
			else
			{
				testSucceeded();
				
				addTest(
					"Delete slivers",
					new DeleteSliversTaskGroup(slice.slivers.Created, false)
				);
			}
		}
		
		// XXX test out removing already created slivers
		// XXX badly formated request rspec
		// XXX non-existing node
		// XXX node which is not available
	}
}