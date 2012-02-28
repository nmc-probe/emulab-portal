package com.flack.emulab.resources
{
	public class NamedObject
	{
		[Bindable]
		public var name:String;
		public function NamedObject(newName:String = "")
		{
			name = newName;
		}
	}
}