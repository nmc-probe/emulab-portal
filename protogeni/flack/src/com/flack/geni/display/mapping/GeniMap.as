/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2012 University of Utah and the Flux Group.
* All rights reserved.
*
* Permission to use, copy, modify and distribute this software is hereby
* granted provided that (1) source code retains these copyright, permission,
* and disclaimer notices, and (2) redistributions including binaries
* reproduce the notices in supporting documentation.
*
* THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
* CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
* FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
*/

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