package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.NamedObject;
	
	public class NumberValuePair
	{
		public var number:int;
		public var value:String;
		public function NumberValuePair(newNumber:int=-1, newValue:String="")
		{
			number = newNumber;
			value = newValue;
		}
	}
}