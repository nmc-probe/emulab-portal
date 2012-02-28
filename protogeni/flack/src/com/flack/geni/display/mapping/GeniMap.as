package com.flack.geni.display.mapping
{
	import com.flack.geni.resources.physical.PhysicalLocationCollection;

	public interface GeniMap
	{
		function get Ready():Boolean;
		
		function zoomToFit(bounds:LatitudeLongitudeBounds):void;
		function panToPoint(center:LatitudeLongitude):void;
		
		function getZoomLevel():Number;		// according to google maps....
		
		function getNewNodeMarker(newLocations:PhysicalLocationCollection, newNodes:*):GeniMapNodeMarker;
		function getNewLink(connectedNodes:Vector.<GeniMapNodeMarker>):GeniMapLink;
		
		function addNodeMarker(marker:GeniMapNodeMarker):void;
		function addLink(link:GeniMapLink):void;
		
		function removeNodeMarker(marker:GeniMapNodeMarker):void;
		function removeLink(link:GeniMapLink):void;
		
		function clearAllOverlays():void;
	}
}