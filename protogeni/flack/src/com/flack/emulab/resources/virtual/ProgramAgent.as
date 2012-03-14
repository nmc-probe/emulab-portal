package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.NamedObject;
	
	public class ProgramAgent extends NamedObject
	{
		public var command:String = "";
		public var directory:String = "";
		public var timeout:Number = NaN;
		public var expectedExitCode:Number = NaN;
		
		public var unsubmittedChanges:Boolean = true;
		
		public function ProgramAgent(newName:String="")
		{
			super(newName);
		}
	}
}