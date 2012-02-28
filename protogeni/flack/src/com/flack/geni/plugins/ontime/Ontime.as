package com.flack.geni.plugins.ontime
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	import com.flack.geni.plugins.ontime.ottasks.InstrumentizeSliceGroupTask;
	import com.flack.geni.resources.virtual.Slice;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.tasks.TaskCollection;
	
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	public class Ontime implements Plugin
	{
		public function get Title():String { return "OnTime" };
		public function get Area():PluginArea { return new OntimeArea() };
		
		public function Ontime()
		{
			super();
		}
		
		public function init():void
		{
			SharedMain.sharedDispatcher.addEventListener(FlackEvent.CHANGED_SLICE, slicePopulated);
		}
		
		// Once a slice is populated, figure out if it is instrumentized if there is a MC node present
		public function slicePopulated(e:FlackEvent):void
		{
			if(e.action == FlackEvent.ACTION_POPULATED)
			{
				var slice:Slice = e.changedObject as Slice;
				var hasMCNode:Boolean = false;
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					if(doesSliverHaveMc(sliver))
						hasMCNode = true;
				}
				if(hasMCNode)
				{
					instrumentizeSlice(slice, false, 1, false, true);
				}
			}
		}
		
		// XML-RPC Module
		public static const instoolsModule:String = "instools";
		
		// XML-RPC Methods
		public static const getInstoolsVersion:String = "GetINSTOOLSVersion";
		public static const addMCNode:String = "AddMCNode";
		public static const getInstoolsStatus:String = "getInstoolsStatus";
		public static const instrumentize:String = "Instrumentize";
		
		// Global INSTOOLS version
		public static var devel_version:Dictionary = new Dictionary();
		public static var stable_version:Dictionary = new Dictionary();
		
		public static var instruemtizeDetails:Dictionary = new Dictionary();
		
		public static function doesSliverHaveMc(sliver:Sliver):Boolean
		{
			if(sliver.Created)
			{
				if(sliver.manifest.document.indexOf("MC=\"1\"") != -1)
					return true;
			}
			return false;
		}
		
		/**
		 * 
		 * @param slice
		 * @return TRUE on success
		 * 
		 */
		public static function instrumentizeSlice(slice:Slice, creating:Boolean = true, useVersion:Number = 1, useVirtualMCs:Boolean = false, ignoreOtherTasks:Boolean = false):void
		{
			var newDetails:SliceOntimeDetails = resetSliceDetails(slice, creating, useVersion, useVirtualMCs);
			
			if(!ignoreOtherTasks)
			{
				var pendingTasks:TaskCollection = SharedMain.tasker.tasks.NotFinished;
				// Wait for any slice tasks to finish before trying to instrumentize
				if(pendingTasks.All.NotFinished.getRelatedTo(slice).length > 0)
				{
					Alert.show("There are tasks running which involve the slice, please wait for them to finish.");
					return;
				}
			}
			
			if(!creating)
			{
				for each(var sliver:Sliver in slice.slivers.collection)
				{
					newDetails.MC_present[sliver.manager.id.full] = doesSliverHaveMc(sliver);
				}
			}
			
			// Do it!
			var instrumentizeTask:InstrumentizeSliceGroupTask = new InstrumentizeSliceGroupTask(newDetails);
			instrumentizeTask.forceRunNow = true;
			SharedMain.tasker.add(instrumentizeTask);
		}
		
		public static function resetSliceDetails(slice:Slice, creating:Boolean = true, useVersion:Number = 1, useVirtualMCs:Boolean = false):SliceOntimeDetails
		{
			// Clear any cached info for the slice and initalize
			if(instruemtizeDetails[slice.id.full] != null)
				delete instruemtizeDetails[slice.id.full];
			var newDetails:SliceOntimeDetails = new SliceOntimeDetails(slice, useVersion, creating, useVirtualMCs);
			instruemtizeDetails[slice.id.full] = newDetails;
			return newDetails;
		}
		
		public static function goToPortal(slice:Slice):void
		{
			var sliceDetails:SliceOntimeDetails = instruemtizeDetails[slice.id.full];
			if(sliceDetails == null)
				Alert.show("Slice either has not been instrumentized or the instrumentation details have not been retrieved. Please click the instrumentize button if you need to instrumentize the slice or if the slice is already instrumentized.");
			else
			{
				if(sliceDetails.hasAnyPortal())
					sliceDetails.goToPortal();
				else
				{
					var pendingTasks:TaskCollection = SharedMain.tasker.tasks.NotFinished.getOfClass(InstrumentizeSliceGroupTask);
					for each(var pendingInstrumentizeTask:InstrumentizeSliceGroupTask in pendingTasks.collection)
					{
						if(pendingInstrumentizeTask.details.slice == slice)
						{
							Alert.show("The slice is currently being instrumentized, please wait for the portal to be created.");
							return;
						}
					}
					Alert.show("The slice doesn't have any portal information yet.");
				}
			}
		}
	}
}