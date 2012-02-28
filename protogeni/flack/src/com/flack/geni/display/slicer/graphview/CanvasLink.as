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

package com.flack.geni.display.slicer.graphview
{
	import com.flack.geni.resources.virtual.LinkType;
	import com.flack.geni.resources.virtual.VirtualComponent;
	import com.flack.geni.resources.virtual.VirtualLink;
	import com.flack.shared.utils.ColorUtil;
	
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	
	import flash.filters.GlowFilter;
	
	import mx.core.UIComponent;
	
	/**
	 * VirtualLink for use on the slice canvas
	 * 
	 * @author mstrum
	 * 
	 */
	public final class CanvasLink extends UIComponent
	{
		public static const NORMAL_COLOR:uint = 0x000000;
		public static const TUNNEL_COLOR:uint = 0x00FFFF;
		public static const ION_COLOR:uint = 0xCC33CC;
		public static const GPENI_COLOR:uint = 0x0000FF;
		
		public static const INVALID_COLOR:uint = 0xFF0000;
		public static const VALID_COLOR:uint = 0x00FF00;
		
		public static var color:uint;
		
		public var link:VirtualLink;
		public var canvas:SliceCanvas;
		
		private var rawSprite:Sprite;
		
		public var buttonGroups:Vector.<CanvasLinkLabel>
		
		public function setFilters(newFilters:Array):void
		{
			rawSprite.filters = newFilters;
			for each(var d:CanvasLinkLabel in buttonGroups)
				d.setFilters(newFilters);
		}
		
		public function CanvasLink(newCanvas:SliceCanvas)
		{
			super();
			canvas = newCanvas;
			
			rawSprite = new Sprite();
			addChild(rawSprite);
			
			color = NORMAL_COLOR;
			
			buttonGroups = new Vector.<CanvasLinkLabel>()
		}
		
		public function setToStatus():void
		{
			var newBackgroundColor:uint = color;
			if(link != null)
			{
				switch(link.status)
				{
					case VirtualComponent.STATUS_READY:
						newBackgroundColor = ColorUtil.validLight;
						toolTip = link.state;
						break;
					case VirtualComponent.STATUS_FAILED:
						newBackgroundColor = ColorUtil.invalidLight;
						toolTip = "Error: " + link.error;
						break;
					case VirtualComponent.STATUS_CHANGING:
						newBackgroundColor = ColorUtil.changingLight;
						toolTip = "Status is changing...";
						break;
					case VirtualComponent.STATUS_NOTREADY:
						newBackgroundColor = ColorUtil.changingLight;
						toolTip = "Link is not ready";
						break;
					case VirtualComponent.STATUS_UNKNOWN:
					default:
						newBackgroundColor = color;
				}
			}
			else
				toolTip = "";
			
			for each(var d:CanvasLinkLabel in buttonGroups)
			{
				d.Link = link;
				d.color = newBackgroundColor;
			}
		}
		
		public function clearStatus():void
		{
			toolTip = "";
			for each(var d:CanvasLinkLabel in buttonGroups)
				d.color = ColorUtil.unknownLight;
		}
		
		public function establishFromExisting(vl:VirtualLink):void
		{
			removeButtonsFromCanvas();
			link = vl;
			
			buttonGroups = new Vector.<CanvasLinkLabel>();
			var canvasNodes:CanvasNodeCollection = canvas.allNodes.getForVirtualNodes(link.interfaceRefs.Interfaces.Nodes);
			for(var i:int = 0; i < canvasNodes.length; i++)
			{
				for(var j:int = i+1; j < canvasNodes.length; j++)
				{
					var newLinkContainer:CanvasLinkLabel = new CanvasLinkLabel();
					newLinkContainer.color = color;
					newLinkContainer.canvasLink = this;
					canvas.addElementAt(newLinkContainer, 0);
					newLinkContainer.validateNow();
					newLinkContainer.Link = link;
					
					buttonGroups.push(newLinkContainer);
				}
			}
			canvas.validateNow();
			canvas.setElementIndex(this, 0);
			drawEstablished();
		}
		
		private var editable:Boolean = true;
		public function setEditable(isEditable:Boolean):void
		{
			editable = isEditable;
			for each(var g:CanvasLinkLabel in buttonGroups)
				g.editable = editable;
		}
		
		private function removeButtonsFromCanvas():void
		{
			for each(var g:CanvasLinkLabel in buttonGroups)
				canvas.removeElement(g);
		}
		
		public function removeFromCanvas():void
		{
			removeButtonsFromCanvas();
			canvas.removeElement(this);
		}
		
		
		public function drawEstablished():void
		{
			color = NORMAL_COLOR;
			switch(link.type.name) {
				case LinkType.GRETUNNEL_V2:
					color = TUNNEL_COLOR;
					break;
				case LinkType.GPENI:
					color = GPENI_COLOR;
					break;
				case LinkType.ION:
					color = ION_COLOR;
					break;
			}
			drawLink();
		}
		
		private function drawLink():void
		{
			rawSprite.graphics.clear();
			rawSprite.graphics.lineStyle(2, color, 1.0, true,
				LineScaleMode.NORMAL, CapsStyle.ROUND);
			
			var canvasNodes:CanvasNodeCollection = canvas.allNodes.getForVirtualNodes(link.interfaceRefs.Interfaces.Nodes);
			
			var buttonGroupsIdx:int = 0;
			for(var i:int = 0; i < canvasNodes.length; i++)
			{
				var firstCanvasNode:CanvasNode = canvasNodes.collection[i];
				for(var j:int = i+1; j < canvasNodes.length; j++, buttonGroupsIdx++)
				{
					var secondCanvasNode:CanvasNode = canvasNodes.collection[j];
					
					var buttonGroup:CanvasLinkLabel = buttonGroups[buttonGroupsIdx];
					buttonGroup.Link = link;
					buttonGroup.x = (firstCanvasNode.MiddleX + secondCanvasNode.MiddleX)/2 - (buttonGroup.ContainerWidth/2 + 1);
					buttonGroup.y = (firstCanvasNode.MiddleY + secondCanvasNode.MiddleY)/2 - (buttonGroup.ContainerHeight/2);
					
					rawSprite.graphics.moveTo(firstCanvasNode.MiddleX, firstCanvasNode.MiddleY);
					rawSprite.graphics.lineTo(secondCanvasNode.MiddleX, secondCanvasNode.MiddleY);
				}
			}
			
			setToStatus();
		}
	}
}