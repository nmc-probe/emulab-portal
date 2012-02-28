package com.flack.emulab.resources.virtual
{
	import com.flack.emulab.resources.NamedObject;
	
	public class VirtualType extends NamedObject
	{
		public var types:Vector.<String>;
		public var weight:Number = NaN;
		public var hard:Boolean = false;
		public function VirtualType(newName:String="")
		{
			super(newName);
		}
	}
}