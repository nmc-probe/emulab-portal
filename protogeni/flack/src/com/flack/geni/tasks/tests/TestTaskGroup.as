package com.flack.geni.tasks.tests
{
	import com.flack.shared.tasks.SerialTaskGroup;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.tasks.TaskEvent;
	import com.flack.shared.tasks.TaskGroup;
	
	public class TestTaskGroup extends SerialTaskGroup
	{
		protected function get NextStepNumber():int
		{
			return tasks.length+1;
		}
		
		protected function get PreviousStepNumber():int
		{
			return tasks.length;
		}
		
		public function TestTaskGroup(taskFullName:String="Serial tasks", taskDescription:String="Runs tasks one after the other", taskShortName:String="", taskParent:TaskGroup=null, taskSkipErrors:Boolean=true)
		{
			super(taskFullName, taskDescription, taskShortName, taskParent, taskSkipErrors);
		}
		
		override protected function runStart():void
		{
			if(tasks.length == 0)
				startTest();
			else
				super.runStart();
		}
		
		protected function startTest():void
		{
			// override and start here!
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=true):void
		{
			super.afterComplete(addCompletedMessage);
		}
		
		protected function testFailed(msg:String = ""):void
		{
			afterError(
				new TaskError(
					"Failed #"+PreviousStepNumber + (msg.length ? ": " + msg : ""),
					TaskError.CODE_UNEXPECTED
				)
			);
		}
		
		protected function testSucceeded():void
		{
			addMessage(
				"Completed #"+PreviousStepNumber,
				description
			);
		}
		
		protected function addTest(description:String, testTask:Task, callAfterFinished:Function = null):void
		{
			addMessage(
				"Step #"+NextStepNumber+": " + description,
				description
			);
			
			if(callAfterFinished != null)
				testTask.addEventListener(TaskEvent.FINISHED, callAfterFinished);
			add(testTask);
		}
		
		protected function testsSucceeded():void
		{
			addMessage(
				"Finished",
				"All slice tests have run successfully"
			);
		}
	}
}