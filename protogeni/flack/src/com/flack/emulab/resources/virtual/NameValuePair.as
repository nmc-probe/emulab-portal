package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.NamedObject;
	
	public class NameValuePair extends NamedObject
	{
		public var value:String;
		public function NameValuePair(newName:String="", newValue:String="")
		{
			super(newName);
			value = newValue;
		}
	}
}