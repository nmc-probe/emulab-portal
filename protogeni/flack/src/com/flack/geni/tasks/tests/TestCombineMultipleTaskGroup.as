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
	import com.flack.geni.plugins.instools.Instools;
	import com.flack.geni.plugins.instools.instasks.InstrumentizeSliceGroupTask;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.groups.slice.CreateSliceTaskGroup;
	import com.flack.geni.tasks.groups.slice.ImportSliceTaskGroup;
	import com.flack.geni.tasks.groups.slice.SubmitSliceTaskGroup;
	import com.flack.geni.tasks.process.GenerateRequestManifestTask;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.shared.SharedMain;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskEvent;
	import com.flack.shared.tasks.http.HttpTask;
	
	/**
	 * Runs a series of tests to see if the code for working with slices is correct
	 * 
	 * @author mstrum
	 * 
	 */
	public final class TestCombineMultipleTaskGroup extends TestTaskGroup
	{
		public function TestCombineMultipleTaskGroup()
		{
			super(
				"Test multiple",
				"Test multiple"
			);
		}
		
		override protected function startTest():void
		{
			var blankSlice:Slice = new Slice();
			(new ParseRequestManifestTask(new Sliver(blankSlice, GeniMain.geniUniverse.managers.getByHrn("utahemulab.cm")) , new Rspec((new TestsliceRspecRight()).toString()), true)).start();
			(new ParseRequestManifestTask(new Sliver(blankSlice, GeniMain.geniUniverse.managers.getByHrn("ukgeni.cm")) , new Rspec((new TestsliceRspecLeft()).toString()), true)).start();
			
			var generate:GenerateRequestManifestTask = new GenerateRequestManifestTask(blankSlice.slivers.collection[0], true, false, false);
			generate.start();
			
			var test:String = generate.resultRspec.document;
		}
	}
}