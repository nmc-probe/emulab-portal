package com.flack.geni.display.mapping
{
	import com.flack.geni.resources.physical.PhysicalLocation;

	public interface GeniMapNodeMarker
	{
		function get Visible():Boolean;
		function get LatitudeLongitudeLocation():LatitudeLongitude;
		function sameLocationAs(testLocations:Vector.<PhysicalLocation>):Boolean;
		
		function setLook(newNodes:*):void;
		
		function hide():void;
		function show():void;
	}
}