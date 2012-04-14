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
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.tasks.groups.slice.CreateSliceTaskGroup;
	import com.flack.geni.tasks.groups.slice.DeleteSliversTaskGroup;
	import com.flack.geni.tasks.groups.slice.SubmitSliceTaskGroup;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskEvent;
	
	/**
	 * 
	 * 1. Create Slice
	 * 2. Add 3 nodes and submit
	 * 3. Undo until the first node was added and submit
	 * 4. Redo until the 3 nodes are back and submit
	 * 5. Deallocate
	 * 
	 * @author mstrum
	 * 
	 */
	public final class TestSliceHistoryTaskGroup extends TestTaskGroup
	{
		public function TestSliceHistoryTaskGroup()
		{
			super(
				"Slice history test",
				"Tests the history feature"
			);
		}
		
		override protected function startTest():void
		{
			addTest(
				"Create slice",
				new CreateSliceTaskGroup(
					"test" + Math.floor(Math.random()*1000000),
					GeniMain.geniUniverse.user.authority
				), 
				firstSliceCreated
			);
		}
		
		public function firstSliceCreated(event:TaskEvent):void
		{
			var slice:Slice = (event.task as CreateSliceTaskGroup).newSlice;
			
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed();
			else
			{
				testSucceeded();
				
				addMessage(
					"Preparing Step #" + NextStepNumber,
					"Preparing slice with a history"
				);
				
				var addFirstNode:VirtualNode = new VirtualNode(
					slice,
					GeniMain.geniUniverse.managers.getByHrn("utahemulab.cm"),
					"test0",
					true,
					RawPcSliverType.TYPE_RAWPC_V2
				);
				slice.nodes.add(addFirstNode);
				slice.history.stateName = "Added first node";
				slice.pushState();
				
				var addSecondNode:VirtualNode = new VirtualNode(
					slice,
					addFirstNode.manager,
					"test1",
					true,
					RawPcSliverType.TYPE_RAWPC_V2
				);
				slice.nodes.add(addSecondNode);
				slice.history.stateName = "Added second node";
				slice.pushState();
				
				var addThirdNode:VirtualNode = new VirtualNode(
					slice,
					addFirstNode.manager,
					"test2",
					true,
					RawPcSliverType.TYPE_RAWPC_V2
				);
				slice.nodes.add(addThirdNode);
				slice.history.stateName = "Added third node";
				
				addTest(
					"Submit slice",
					new SubmitSliceTaskGroup(slice), 
					firstSliceSubmitted
				);
			}
		}
		
		public function firstSliceSubmitted(event:TaskEvent):void
		{
			var slice:Slice = (event.task as SubmitSliceTaskGroup).slice;
			
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed();
			else
			{
				addMessage(
					"Slice details post-submit",
					slice.toString()
				);
				
				testSucceeded();
				
				addMessage(
					"Preparing Step #" + NextStepNumber,
					"Undoing history until the oldest history item"
				);
				
				var oldState:String = "";
				while(slice.history.backIndex > -1)
				{
					addMessage(
						"Slice state popped",
						slice.toString()
					);
					oldState = slice.backState();
				}
				
				addMessage(
					"Slice details pre-submit",
					slice.toString()
				);
				
				addTest(
					"Submit slice",
					new SubmitSliceTaskGroup(slice), 
					backToStartSliceSubmitted
				);
			}
		}
		
		public function backToStartSliceSubmitted(event:TaskEvent):void
		{
			var slice:Slice = (event.task as SubmitSliceTaskGroup).slice;
			
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed();
			else
			{
				addMessage(
					"Slice details post-submit",
					slice.toString()
				);
				
				testSucceeded();
				
				addMessage(
					"Preparing Step #" + NextStepNumber,
					"Going forward to the latest history item"
				);
				
				var oldState:String = "";
				slice.forwardState();
				while(slice.CanGoForward)
				{
					addMessage(
						"Slice state popped",
						slice.toString()
					);
					oldState = slice.forwardState();
				}
				
				addMessage(
					"Slice details pre-submit",
					slice.toString()
				);
				
				addTest(
					"Submit slice",
					new SubmitSliceTaskGroup(slice), 
					finishedSliceSubmitted
				);
			}
		}
		
		public function finishedSliceSubmitted(event:TaskEvent):void
		{
			var slice:Slice = (event.task as SubmitSliceTaskGroup).slice;
			
			if(event.task.Status != Task.STATUS_SUCCESS)
				testFailed();
			else
			{
				addMessage(
					"Slice details post-submit",
					slice.toString()
				);
				
				testSucceeded();
				
				addTest(
					"Submit slice",
					new DeleteSliversTaskGroup(slice.slivers, false)
				);
			}
		}
	}
}