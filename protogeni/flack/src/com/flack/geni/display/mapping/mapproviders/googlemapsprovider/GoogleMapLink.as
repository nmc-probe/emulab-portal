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

package com.flack.geni.display.mapping.mapproviders.googlemapsprovider
{
	import com.flack.geni.display.DisplayUtil;
	import com.flack.geni.display.mapping.GeniMapLink;
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.resources.physical.PhysicalLinkCollection;
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.geni.resources.virtual.VirtualLinkCollection;
	import com.flack.shared.utils.NetUtil;
	import com.google.maps.LatLng;
	import com.google.maps.overlays.Polyline;
	import com.google.maps.overlays.PolylineOptions;
	import com.google.maps.styles.StrokeStyle;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * Visual representation of a link on Google Maps
	 * 
	 * @author mstrum
	 * 
	 */
	public class GoogleMapLink implements GeniMapLink
	{
		public static const LINK_COLOR:Object = 0xFFCFD1;
		public static const LINK_BORDER_COLOR:Object = 0xFF00FF;
		
		public var polyline:Polyline;
		public var labels:Vector.<GoogleTooltipOverlay>;
		
		public var markers:Vector.<GeniMapNodeMarker>;
		public var connectedPoints:Array;
		
		public var links:*;
		
		public function GoogleMapLink(connectedMarkers:Vector.<GeniMapNodeMarker>)
		{
			markers = connectedMarkers;
			
			connectedPoints = [];
			for each(var marker:GeniMapNodeMarker in markers)
				connectedPoints.push((marker as GoogleMapLocationMarker).getLatLng());
			
			// Add line
			polyline = new Polyline(
				connectedPoints,
				new PolylineOptions(
					{
						strokeStyle: new StrokeStyle(
							{
								color: LINK_BORDER_COLOR,
								thickness: 4,
								alpha:1
							}
						)
					}
				)
			);
		}
		
		public function addLinks(newLinks:*):void
		{
			if(links == null)
			{
				if(newLinks is VirtualLinkCollection)
					links = new VirtualLinkCollection();
				else
					links = new PhysicalLinkCollection();
			}
			
			for each(var link:* in newLinks.collection)
			{
				if(!links.contains(link))
					links.add(link);
			}
		}
		
		public function addLink(newLink:*):void
		{
			if(links == null)
			{
				if(newLink is VirtualLink)
					links = new VirtualLinkCollection();
				else
					links = new PhysicalLinkCollection();
			}
			
			if(!links.contains(newLink))
				links.add(newLink);
		}
		
		public function generateLabels():void
		{
			labels = new Vector.<GoogleTooltipOverlay>();
			var labelName:String = NetUtil.kbsToString(links.MaximumCapacity);
			for(var i:int = 1; i < connectedPoints.length; i++)
			{
				var label:GoogleTooltipOverlay = new GoogleTooltipOverlay(
					new LatLng(
						(connectedPoints[i-1].lat() + connectedPoints[i].lat())/2,
						(connectedPoints[i-1].lng() + connectedPoints[i].lng())/2),
					labelName,
					LINK_BORDER_COLOR,
					LINK_COLOR);
				label.addEventListener(MouseEvent.CLICK, openLinks);
				// XXX no remove event
				labels.push(label);
			}
		}
		
		public function openLinks(e:Event):void
		{
			e.stopImmediatePropagation();
			DisplayUtil.view(links);
		}
		
		public function sameMarkersAs(testMarkers:Vector.<GeniMapNodeMarker>):Boolean
		{
			if(testMarkers.length != markers.length)
				return false;
			for each(var testMarker:GeniMapNodeMarker in testMarkers)
			{
				if(markers.indexOf(testMarker) == -1)
					return false;
			}
			return true;
		}
	}
}