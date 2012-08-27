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
	import com.flack.geni.GeniMain;
	import com.google.maps.controls.ControlBase;
	import com.google.maps.controls.ControlPosition;
	import com.google.maps.interfaces.IMap;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class GoogleZoomToAllControl extends ControlBase
	{
		public function GoogleZoomToAllControl()
		{
			super(new ControlPosition(ControlPosition.ANCHOR_TOP_RIGHT, 57, 7));
		}
		
		public override function initControlWithMap(map:IMap):void {
			// first call the base class
			super.initControlWithMap(map);
			createButton("Fit all", 0, 0, function(event:Event):void { GeniMain.mapper.zoomToAll()});
		}
		
		private function createButton(text:String,x:Number,y:Number,callback:Function):void {
			var button:Sprite = new Sprite();
			button.x = x;
			button.y = y;
			
			var buttonWidth:Number = 50;
			
			var label:TextField = new TextField();
			label.text = text;
			label.width = buttonWidth;
			label.selectable = false;
			label.autoSize = TextFieldAutoSize.CENTER;
			var format:TextFormat = new TextFormat("Verdana");
			label.setTextFormat(format);
			
			var background:Shape = new Shape();
			background.graphics.beginFill(0xFFFFFF);
			background.graphics.lineStyle(1, 0x000000);
			background.graphics.drawRoundRect(0, 0, buttonWidth, 18, 4);
			background.graphics.endFill();
			
			button.addChild(background);
			button.addChild(label);
			button.addEventListener(MouseEvent.CLICK, callback);
			
			addChild(button);
		}
	}
}