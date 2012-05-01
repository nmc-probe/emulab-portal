package com.flack.geni.display.mapping.mapproviders.esriprovider
{
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.symbols.MarkerSymbol;
	import com.esri.ags.symbols.Symbol;
	import com.flack.geni.resources.physical.PhysicalNodeCollection;
	import com.flack.geni.resources.sites.GeniManagerCollection;
	import com.flack.geni.resources.virtual.VirtualNodeCollection;
	import com.flack.shared.utils.ColorUtil;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import mx.core.DragSource;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.managers.DragManager;
	
	public class EsriMapNodeMarkerSymbol extends Symbol
	{
		private var marker:EsriMapNodeMarker;
		public function EsriMapNodeMarkerSymbol(newMarker:EsriMapNodeMarker)
		{
			super();
			marker = newMarker;
		}
		
		override public function clear(sprite:Sprite):void
		{
			removeAllChildren(sprite);
			sprite.graphics.clear();
			sprite.x = 0;
			sprite.y = 0;
			sprite.filters = [];
			sprite.buttonMode = false;
		}
		
		
		override public function destroy(sprite:Sprite):void
		{
			clear(sprite);
		}
		
		override public function draw(sprite:Sprite,
									  geometry:Geometry,
									  attributes:Object,
									  map:Map):void
		{
			if (geometry is MapPoint)
			{
				var managers:GeniManagerCollection = marker.Nodes.Managers;
				
				var mapPoint:MapPoint = MapPoint(geometry) as MapPoint;
				sprite.x = toScreenX(map, mapPoint.x)-14-Math.min(3*((marker.Nodes as PhysicalNodeCollection).Locations.length-1), 6)/2;
				sprite.y = toScreenY(map, mapPoint.y)-14-Math.min(3*((marker.Nodes as PhysicalNodeCollection).Locations.length-1), 6)/2;
				
				
				var loc:int;
				if(managers.length > 1)
				{
					var numShownManagers:int = Math.min(managers.length, 5);
					loc = 3*(numShownManagers-1);
					for(var i:int = numShownManagers-1; i > -1; i--)
					{
						sprite.graphics.lineStyle(2, ColorUtil.colorsMedium[managers.collection[i].colorIdx], 1);
						sprite.graphics.beginFill(ColorUtil.colorsDark[managers.collection[i].colorIdx], 1);
						sprite.graphics.drawRoundRect(loc, loc, 28, 28, 10, 10);
						loc -= 3;
					}
				}
				else
				{
					if(marker.Nodes is PhysicalNodeCollection)
						loc = Math.min(3*((marker.Nodes as PhysicalNodeCollection).Locations.length-1), 6);
					else if(marker.Nodes is VirtualNodeCollection)
						loc = Math.min(3*((marker.Nodes as VirtualNodeCollection).PhysicalNodes.Locations.length-1), 6);
					while(loc > -1)
					{
						sprite.graphics.lineStyle(2, ColorUtil.colorsMedium[managers.collection[0].colorIdx], 1);
						sprite.graphics.beginFill(ColorUtil.colorsDark[managers.collection[0].colorIdx], 1);
						sprite.graphics.drawRoundRect(loc, loc, 28, 28, 10, 10);
						loc -= 3;
					}
				}
				
				var labelMc:TextField = new TextField();
				// Temp fix...
				if(managers.length > 0)
					labelMc.textColor = ColorUtil.colorsLight[managers.collection[0].colorIdx];
				labelMc.selectable = false;
				labelMc.border = false;
				labelMc.embedFonts = false;
				labelMc.mouseEnabled = false;
				labelMc.width = 28;
				labelMc.height = 28;
				labelMc.htmlText = marker.Nodes.length.toString();
				labelMc.autoSize = TextFieldAutoSize.CENTER;
				labelMc.y = 4;
				sprite.addChild(labelMc);
				
				// Apply the drop shadow filter to the box.
				var shadow:DropShadowFilter = new DropShadowFilter();
				shadow.distance = 5;
				shadow.angle = 25;
				sprite.filters = [shadow];
				
				sprite.buttonMode = true;
				sprite.useHandCursor = true;
			}
		}
		
		public function getCopy():UIComponent
		{
			var managers:GeniManagerCollection = marker.Nodes.Managers;
			
			var holder:UIComponent = new UIComponent();
			var sprite:Sprite = new Sprite();
			var loc:int;
			if(managers.length > 1)
			{
				var numShownManagers:int = Math.min(managers.length, 5);
				loc = 3*(numShownManagers-1);
				for(var i:int = numShownManagers-1; i > -1; i--)
				{
					sprite.graphics.lineStyle(2, ColorUtil.colorsMedium[managers.collection[i].colorIdx], 1);
					sprite.graphics.beginFill(ColorUtil.colorsDark[managers.collection[i].colorIdx], 1);
					sprite.graphics.drawRoundRect(loc, loc, 28, 28, 10, 10);
					loc -= 3;
				}
			}
			else
			{
				if(marker.Nodes is PhysicalNodeCollection)
					loc = Math.min(3*((marker.Nodes as PhysicalNodeCollection).Locations.length-1), 6);
				else if(marker.Nodes is VirtualNodeCollection)
					loc = Math.min(3*((marker.Nodes as VirtualNodeCollection).PhysicalNodes.Locations.length-1), 6);
				while(loc > -1)
				{
					sprite.graphics.lineStyle(2, ColorUtil.colorsMedium[managers.collection[0].colorIdx], 1);
					sprite.graphics.beginFill(ColorUtil.colorsDark[managers.collection[0].colorIdx], 1);
					sprite.graphics.drawRoundRect(loc, loc, 28, 28, 10, 10);
					loc -= 3;
				}
			}
			
			var labelMc:TextField = new TextField();
			labelMc.textColor = ColorUtil.colorsLight[managers.collection[0].colorIdx];
			labelMc.selectable = false;
			labelMc.border = false;
			labelMc.embedFonts = false;
			labelMc.mouseEnabled = false;
			labelMc.width = 28;
			labelMc.height = 28;
			labelMc.htmlText = "<b>"+marker.Nodes.length.toString()+"</b>";
			labelMc.autoSize = TextFieldAutoSize.CENTER;
			labelMc.y = 4;
			sprite.addChild(labelMc);
			holder.addChild(sprite);
			
			// Apply the drop shadow filter to the box.
			var shadow:DropShadowFilter = new DropShadowFilter();
			shadow.distance = 5;
			shadow.angle = 25;
			holder.filters = [shadow];
			
			return holder;
		}
	}
}