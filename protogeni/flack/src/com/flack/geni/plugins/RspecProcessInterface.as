package com.flack.geni.plugins
{
	import com.flack.geni.resources.virtual.Sliver;

	public interface RspecProcessInterface
	{
		function applyFrom(object:*, xml:XML):void;
		function applyTo(sliver:Sliver, xml:XML):void;
		
		function get namespace():Namespace;
		function get schema():String;
	}
}