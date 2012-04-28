package com.flack.geni.display.mapping.mapproviders.esriprovider
{
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.WebMercatorMapPoint;
	import com.flack.geni.display.DisplayUtil;
	import com.flack.geni.display.mapping.GeniMapNodeMarker;
	import com.flack.geni.display.mapping.LatitudeLongitude;
	import com.flack.geni.resources.physical.PhysicalLocation;
	import com.flack.geni.resources.physical.PhysicalLocationCollection;
	import com.flack.geni.resources.physical.PhysicalNodeCollection;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;
	
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.core.DragSource;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	public class EsriMapLinkMarker extends Graphic
	{
		public var mapPoint:WebMercatorMapPoint;
		public var link:EsriMapLink;
		
		public function EsriMapLinkMarker(newLink:EsriMapLink,
										  newPoint:WebMercatorMapPoint,
										  newLabel:String,
										  edgeColor:Object,
										  backColor:Object)
		{
			super(newPoint);
			link = newLink;
			mapPoint = newPoint;
			
			symbol = new EsriMapLinkMarkerSymbol(
				this,
				newLabel,
				edgeColor,
				backColor);
			
			addEventListener(MouseEvent.CLICK, clicked);
		}
		
		public function destroy():void
		{
			removeEventListener(MouseEvent.CLICK, clicked);
		}
		
		public function clicked(e:MouseEvent):void
		{
			e.stopPropagation();
			DisplayUtil.view(link.links);
		}
	}
}