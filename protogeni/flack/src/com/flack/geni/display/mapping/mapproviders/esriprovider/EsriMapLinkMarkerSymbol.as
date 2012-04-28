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
	import flash.text.TextFormat;
	
	import mx.core.DragSource;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.managers.DragManager;
	
	public class EsriMapLinkMarkerSymbol extends Symbol
	{
		private var marker:EsriMapLinkMarker;
		
		private var label:String;
		
		private var borderColor:Object;
		private var backgroundColor:Object;
		
		public function EsriMapLinkMarkerSymbol(newMarker:EsriMapLinkMarker,
												newLabel:String,
												edgeColor:Object,
												backColor:Object)
		{
			super();
			borderColor = edgeColor;
			backgroundColor = backColor;
			marker = newMarker;
			label = newLabel;
		}
		
		override public function draw(sprite:Sprite,
									  geometry:Geometry,
									  attributes:Object,
									  map:Map):void
		{
			if (geometry is MapPoint)
			{
				var mapPoint:MapPoint = MapPoint(geometry) as MapPoint;
				sprite.x = toScreenX(map, mapPoint.x)-52;
				sprite.y = toScreenY(map, mapPoint.y)-14;
				
				var textFormat:TextFormat = new TextFormat();
				textFormat.size = 15;
				var textField:TextField = new TextField();
				textField.defaultTextFormat = textFormat;
				textField.text = label;
				textField.selectable = false;
				textField.border = true;
				textField.borderColor = borderColor as uint;
				textField.background = true;
				textField.multiline = false;
				textField.autoSize = TextFieldAutoSize.CENTER;
				textField.backgroundColor = backgroundColor as uint;
				textField.mouseEnabled = false;
				textField.filters = [new DropShadowFilter()];
				
				var button:Sprite = new Sprite();
				button.buttonMode=true;
				button.useHandCursor = true;
				button.addChild(textField);
				
				sprite.addChild(button);
				
				sprite.buttonMode = true;
				sprite.useHandCursor = true;
			}
		}
	}
}