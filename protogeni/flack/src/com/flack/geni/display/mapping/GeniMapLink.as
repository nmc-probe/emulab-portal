package com.flack.geni.display.mapping
{
	public interface GeniMapLink
	{
		function addLink(newLink:*):void;
		function sameMarkersAs(testMarkers:Vector.<GeniMapNodeMarker>):Boolean;
	}
}