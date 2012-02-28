package com.flack.geni.display.mapping.mapproviders.mapquestprovider
{
	import com.flack.geni.display.mapping.GeniMapLink;
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.resources.physical.PhysicalLinkCollection;
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.geni.resources.virtual.VirtualLinkCollection;
	import com.mapquest.LatLngCollection;
	import com.mapquest.tilemap.overlays.LineOverlay;
	import com.mapquest.tilemap.pois.Poi;
	
	import flash.events.Event;

	public class MapquestMapLink implements GeniMapLink
	{
		public static const LINK_COLOR:uint = 0xFFCFD1;
		public static const LINK_BORDER_COLOR:uint = 0xFF00FF;
		
		public var polyline:LineOverlay;
		
		public var markers:Vector.<GeniMapNodeMarker>;
		
		public var links:*;
		
		public function MapquestMapLink(connectedMarkers:Vector.<GeniMapNodeMarker>)
		{
			markers = connectedMarkers;
			
			polyline = new LineOverlay();
			var points:LatLngCollection = new LatLngCollection();
			for each(var marker:GeniMapNodeMarker in markers)
				points.add((marker as Poi).latLng);
			polyline.shapePoints = points;
			
			polyline.borderColor = LINK_BORDER_COLOR;
			polyline.borderColorAlpha = 1;
			polyline.borderWidth = 4;
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
			/*
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
			*/
		}
		
		public function openLinks(e:Event):void
		{
			/*
			e.stopImmediatePropagation();
			DisplayUtil.view(links);
			*/
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