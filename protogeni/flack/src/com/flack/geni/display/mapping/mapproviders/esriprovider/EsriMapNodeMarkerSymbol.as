package com.flack.geni.display.mapping.mapproviders.esriprovider
{
	import com.esri.ags.Map;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.symbols.MarkerSymbol;
	import com.flack.shared.utils.ColorUtil;
	
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class EsriMapNodeMarkerSymbol extends MarkerSymbol
	{
		private var marker:EsriMapNodeMarker
		public function EsriMapNodeMarkerSymbol(newMarker:EsriMapNodeMarker)
		{
			super();
			marker = newMarker;
		}
		
		override public function draw(sprite:Sprite, geometry:Geometry, attributes:Object, map:Map):void
		{
			/*
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
				if(newMarker.nodes is PhysicalNodeCollection)
					loc = Math.min(3*((newMarker.nodes as PhysicalNodeCollection).Locations.length-1), 6);
				else if(newMarker.nodes is VirtualNodeCollection)
					loc = Math.min(3*((newMarker.nodes as VirtualNodeCollection).PhysicalNodes.Locations.length-1), 6);
				while(loc > -1)
				{
					sprite.graphics.lineStyle(2, ColorUtil.colorsMedium[managers.collection[0].colorIdx], 1);
					sprite.graphics.beginFill(ColorUtil.colorsDark[managers.collection[0].colorIdx], 1);
					sprite.graphics.drawRoundRect(loc, loc, 28, 28, 10, 10);
					loc -= 3;
				}
			}
			*/
			
			var labelMc:TextField = new TextField();
			labelMc.textColor = ColorUtil.colorsLight[marker.nodes.Managers.collection[0].colorIdx];
			labelMc.selectable = false;
			labelMc.border = false;
			labelMc.embedFonts = false;
			labelMc.mouseEnabled = false;
			labelMc.width = 28;
			labelMc.height = 28;
			labelMc.htmlText = "<b>"+marker.nodes.length.toString()+"</b>";
			labelMc.autoSize = TextFieldAutoSize.CENTER;
			labelMc.y = 4;
			sprite.addChild(labelMc);
		}
		
		override public function initialize(sprite:Sprite, geometry:Geometry, attributes:Object, map:Map):void
		{
			var labelMc:TextField = new TextField();
			labelMc.textColor = ColorUtil.colorsLight[marker.nodes.Managers.collection[0].colorIdx];
			labelMc.selectable = false;
			labelMc.border = false;
			labelMc.embedFonts = false;
			labelMc.mouseEnabled = false;
			labelMc.width = 28;
			labelMc.height = 28;
			labelMc.htmlText = "<b>"+marker.nodes.length.toString()+"</b>";
			labelMc.autoSize = TextFieldAutoSize.CENTER;
			labelMc.y = 4;
			sprite.addChild(labelMc);
		}
	}
}