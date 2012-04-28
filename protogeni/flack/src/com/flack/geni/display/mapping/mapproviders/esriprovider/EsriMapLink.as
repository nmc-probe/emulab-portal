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
	import com.flack.shared.utils.NetUtil;
	
	public class EsriMapLink implements GeniMapLink
	{
		public static const LINK_COLOR:uint = 0xFFCFD1;
		public static const LINK_BORDER_COLOR:uint = 0xFF00FF;
		
		public var lineGraphic:Graphic;
		public var labelGraphics:Vector.<EsriMapLinkMarker> = new Vector.<EsriMapLinkMarker>();
		
		public var markers:Vector.<GeniMapNodeMarker>;
		public var connectedPoints:Array;
		
		public var links:*;
		
		public function EsriMapLink(connectedMarkers:Vector.<GeniMapNodeMarker>)
		{
			markers = connectedMarkers;
			
			connectedPoints = [];
			for each(var marker:GeniMapNodeMarker in markers)
				connectedPoints.push(new WebMercatorMapPoint(marker.LatitudeLongitudeLocation.longitude, marker.LatitudeLongitudeLocation.latitude));
			
			var polyline:Polyline = new Polyline([connectedPoints], new SpatialReference(4326));
			lineGraphic = new Graphic(polyline);
			lineGraphic.symbol = new SimpleLineSymbol(SimpleLineSymbol.STYLE_SOLID, 0xFF00FF, 1, 4);
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
		
		public function generateLabels():void
		{
			labelGraphics = new Vector.<EsriMapLinkMarker>();
			var labelName:String = NetUtil.kbsToString(links.MaximumCapacity);
			for(var i:int = 1; i < connectedPoints.length; i++)
			{
				var label:EsriMapLinkMarker = new EsriMapLinkMarker(
					this,
					new WebMercatorMapPoint(
						(connectedPoints[i-1].lon + connectedPoints[i].lon)/2,
						(connectedPoints[i-1].lat + connectedPoints[i].lat)/2),
					labelName,
					LINK_BORDER_COLOR,
					LINK_COLOR);
				labelGraphics.push(label);
			}
		}
	}
}