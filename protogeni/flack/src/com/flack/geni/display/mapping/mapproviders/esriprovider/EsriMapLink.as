package com.flack.geni.display.mapping.mapproviders.esriprovider
{
	import com.esri.ags.Graphic;
	import com.esri.ags.SpatialReference;
	import com.esri.ags.geometry.Polyline;
	import com.esri.ags.geometry.WebMercatorMapPoint;
	import com.esri.ags.symbols.SimpleLineSymbol;
	import com.flack.geni.display.mapping.GeniMapLink;
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.resources.physical.PhysicalLinkCollection;
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.geni.resources.virtual.VirtualLinkCollection;
	
	public class EsriMapLink implements GeniMapLink
	{
		public static const LINK_COLOR:uint = 0xFFCFD1;
		public static const LINK_BORDER_COLOR:uint = 0xFF00FF;
		
		public var graphic:Graphic;
		
		public var markers:Vector.<GeniMapNodeMarker>;
		
		public var links:*;
		
		public function EsriMapLink(connectedMarkers:Vector.<GeniMapNodeMarker>)
		{
			markers = connectedMarkers;
			
			var mapPoints:Array = [];
			for each(var marker:GeniMapNodeMarker in markers)
				mapPoints.push(new WebMercatorMapPoint(marker.LatitudeLongitudeLocation.longitude, marker.LatitudeLongitudeLocation.latitude));
			
			var polyline:Polyline = new Polyline([mapPoints], new SpatialReference(4326));
			graphic = new Graphic(polyline);
			graphic.symbol = new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, 0xFF00FF, 1, 4);
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