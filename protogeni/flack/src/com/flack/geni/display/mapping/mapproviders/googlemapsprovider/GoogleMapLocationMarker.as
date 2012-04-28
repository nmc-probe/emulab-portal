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
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.display.mapping.LatitudeLongitude;
	import com.flack.geni.resources.physical.PhysicalLocation;
	import com.flack.geni.resources.physical.PhysicalLocationCollection;
	import com.google.maps.InfoWindowOptions;
	import com.google.maps.LatLng;
	import com.google.maps.MapMouseEvent;
	import com.google.maps.overlays.Marker;
	import com.google.maps.overlays.MarkerOptions;
	
	import flash.events.Event;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	/**
	 * Marker to be used for GENI resources on Google Maps
	 * 
	 * @author mstrum
	 * 
	 */
	public class GoogleMapLocationMarker extends Marker implements GeniMapNodeMarker
	{
		public var infoWindow:UIComponent;
		public var mapIcon:GoogleMapLocationMarkerIcon;
		
		[Bindable]
		public var name:String = "";
		
		public var locations:PhysicalLocationCollection;
		public var location:PhysicalLocation;
		
		public var nodes:*;
		public function get Nodes():*
		{
			return nodes;
		}
		public function set Nodes(value:*):void
		{
			nodes = value;
		}
		
		public function get Visible():Boolean
		{
			return visible;
		}
		
		public function GoogleMapLocationMarker(newLocations:PhysicalLocationCollection,
												newNodes:*)
		{
			var newLocation:PhysicalLocation;
			if(newLocations.length > 1)
				newLocation = newLocations.Middle;
			else
				newLocation = newLocations.collection[0];
			
			super(new LatLng(newLocation.latitude, newLocation.longitude));
			
			location = newLocation;
			locations = newLocations;
			
			setLook(newNodes);
			
			addEventListener(MapMouseEvent.CLICK, clicked);
		}
		
		public function destroy():void
		{
			removeEventListener(MapMouseEvent.CLICK, clicked);
			if(mapIcon != null)
				mapIcon.destroy();
		}
		
		public function setLook(newNodes:*):void
		{
			// Don't redo marker
			if(nodes != null && newNodes.sameAs(nodes))
				return;
			
			nodes = newNodes;
			
			if(nodes != null)
			{
				if(mapIcon != null)
					mapIcon.destroy();
				mapIcon = new GoogleMapLocationMarkerIcon(this);
				setOptions(
					new MarkerOptions(
						{
							icon:mapIcon,
							//icon:new PhysicalNodeGroupClusterMarker(this.showGroups.GetAll().length.toString(), this, showGroups.GetType()),
							//iconAllignment:MarkerOptions.ALIGN_RIGHT,
							iconOffset:new Point(-20, -20)
						}
					)
				);
			}
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
		
		public function clicked(e:Event):void
		{
			var clusterInfo:GoogleMapLocationMarkerInfo = new GoogleMapLocationMarkerInfo();
			clusterInfo.load(this);
			infoWindow = clusterInfo;
			
			openInfoWindow(
				new InfoWindowOptions(
					{
						customContent:infoWindow,
						customoffset:new Point(0, 10),
						width:infoWindow.width,
						height:infoWindow.height,
						drawDefaultFrame:true
					}
				)
			);
		}
		
		public function get LatitudeLongitudeLocation():LatitudeLongitude
		{
			var ll:LatLng = getLatLng();
			return new LatitudeLongitude(ll.lat(), ll.lng());
		}
	}
}