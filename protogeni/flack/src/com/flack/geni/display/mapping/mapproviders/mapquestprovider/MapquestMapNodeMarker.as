package com.flack.geni.display.mapping.mapproviders.mapquestprovider
{
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.display.mapping.LatitudeLongitude;
	import com.flack.geni.resources.physical.PhysicalLocation;
	import com.flack.geni.resources.physical.PhysicalLocationCollection;
	import com.mapquest.LatLng;
	import com.mapquest.tilemap.pois.Poi;
	
	import flash.events.Event;
	
	public class MapquestMapNodeMarker extends Poi implements GeniMapNodeMarker
	{
		//public var markerIcon:MapquestMapLocationMarkerIcon;
		
		[Bindable]
		public var name:String = "";
		
		public var locations:PhysicalLocationCollection;
		public var location:PhysicalLocation;
		
		public var nodes:*;
		
		public function get Visible():Boolean
		{
			return visible;
		}
		
		public function MapquestMapNodeMarker(newLocations:PhysicalLocationCollection,
											  newNodes:*)
		{
			var newLocation:PhysicalLocation;
			if(newLocations.length > 1)
				newLocation = newLocations.Middle;
			else
				newLocation = newLocations.collection[0];
			
			super(new LatLng(newLocation.latitude, newLocation.longitude));
			
			nodes = newNodes;
			location = newLocation;
			locations = newLocations;
		}
		
		public function setLook(newNodes:*):void
		{
			// Don't redo marker
			if(nodes != null && newNodes.sameAs(nodes))
				return;
			
			nodes = newNodes;
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
		
		public function destroy():void
		{
		}
		
		public function clicked(e:Event):void
		{
		}
		
		public function show():void
		{
			super.visible = true;
		}
		
		public function hide():void
		{
			super.visible = false;
		}
		
		public function get LatitudeLongitudeLocation():LatitudeLongitude
		{
			return new LatitudeLongitude(latLng.lat, latLng.lng);
		}
	}
}