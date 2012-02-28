package com.flack.geni.display.mapping.mapproviders.esriprovider
{
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.WebMercatorMapPoint;
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.display.mapping.LatitudeLongitude;
	import com.flack.geni.resources.physical.PhysicalLocation;
	import com.flack.geni.resources.physical.PhysicalLocationCollection;
	
	public class EsriMapNodeMarker extends Graphic implements GeniMapNodeMarker
	{
		public var locations:PhysicalLocationCollection;
		public var location:PhysicalLocation;
		
		public var nodes:*;
		
		public var mapPoint:WebMercatorMapPoint;
		
		public function EsriMapNodeMarker(newLocations:PhysicalLocationCollection,
										  newNodes:*)
		{
			var newLocation:PhysicalLocation;
			if(newLocations.length > 1)
				newLocation = newLocations.Middle;
			else
				newLocation = newLocations.collection[0];
			
			var newMapPoint:WebMercatorMapPoint = new WebMercatorMapPoint(newLocation.longitude, newLocation.latitude);
			
			super(newMapPoint);
			
			mapPoint = newMapPoint;
			nodes = newNodes;
			location = newLocation;
			locations = newLocations;
			
			symbol = new EsriMapNodeMarkerSymbol(this);
		}
		
		public function get Visible():Boolean
		{
			return visible;
		}
		
		public function get LatitudeLongitudeLocation():LatitudeLongitude
		{
			return new LatitudeLongitude(location.latitude, location.longitude);
		}
		
		public function sameLocationAs(testLocations:Vector.<PhysicalLocation>):Boolean
		{
			if(testLocations.length != locations.length)
				return false;
			for each(var testLocation:PhysicalLocation in testLocations)
			{
				if(!locations.contains(testLocation))
					return false;
			}
			return true;
		}
		
		public function setLook(newNodes:*):void
		{
			// Don't redo marker
			if(nodes != null && newNodes.sameAs(nodes))
				return;
			
			nodes = newNodes;
		}
		
		public function hide():void
		{
			visible = false;
		}
		
		public function show():void
		{
			visible = true;
		}
	}
}