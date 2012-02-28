package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.NamedObject;
	
	public class ProgramAgent extends NamedObject
	{
		public var command:String = "";
		public var directory:String = "";
		public var timeout:Number = NaN;
		public var expectedExitCode:int = 0;
		
		public var unsubmittedChanges:Boolean = true;
		
		public function ProgramAgent(newName:String="")
		{
			super(newName);
		}
	}
}