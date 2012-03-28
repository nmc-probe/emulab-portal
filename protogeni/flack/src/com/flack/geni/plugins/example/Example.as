package com.flack.geni.plugins.example
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	
	public class Example implements Plugin
	{
		public function get Title():String { return "Example" };
		public function get Area():PluginArea { return new ExampleArea() };
		
		public function Example()
		{
			super();
		}
		
		public function init():void
		{
		}
	}
}