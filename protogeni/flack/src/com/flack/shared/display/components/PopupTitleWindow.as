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

package com.flack.shared.display.components
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	import spark.events.TitleWindowBoundsEvent;
	
	public class PopupTitleWindow extends TitleWindow
	{
		public function PopupTitleWindow()
		{
			super();
			addEventListener(CloseEvent.CLOSE, closeWindow);
			addEventListener(TitleWindowBoundsEvent.WINDOW_MOVING, onWindowMoving);
		}
		
		public function onWindowMoving(event:TitleWindowBoundsEvent):void {
			var endBounds:Rectangle = event.afterBounds;
			
			// left edge of the stage
			if (endBounds.x < (endBounds.width*-1 + 48))
				endBounds.x = endBounds.width*-1 + 48;
			
			// right edge of the stage
			if (endBounds.x > (FlexGlobals.topLevelApplication.width - 48))
				endBounds.x = FlexGlobals.topLevelApplication.width - 48;
			
			// top edge of the stage
			if (endBounds.y < 0)
				endBounds.y = 0;
			
			// bottom edge of the stage
			if (endBounds.y > (FlexGlobals.topLevelApplication.height - 48))
				endBounds.y = FlexGlobals.topLevelApplication.height - 48;
		}
		
		public function showWindow(center:Boolean = true, modal:Boolean = false):void
		{
			if(!isPopUp)
				PopUpManager.addPopUp(this, FlexGlobals.topLevelApplication as DisplayObject, modal);
			else
				PopUpManager.bringToFront(this);
			if(center)
				PopUpManager.centerPopUp(this);
		}
		
		public function closeWindow(event:Event = null):void
		{
			cleanup();
			PopUpManager.removePopUp(this);
		}
		
		public function cleanup():void {
			removeEventListener(CloseEvent.CLOSE, closeWindow);
			removeEventListener(TitleWindowBoundsEvent.WINDOW_MOVING, onWindowMoving);
		}
	}
}