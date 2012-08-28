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
 
package com.flack.shared.utils
{
	import com.flack.shared.display.areas.AboutArea;
	import com.flack.shared.display.areas.Area;
	import com.flack.shared.display.areas.AreaContent;
	import com.flack.shared.display.areas.LogMessageArea;
	import com.flack.shared.display.components.DataButton;
	import com.flack.shared.display.components.DefaultWindow;
	import com.flack.shared.display.components.DocumentWindow;
	import com.flack.shared.display.components.MultiDocumentWindow;
	import com.flack.shared.logging.LogMessage;
	
	import spark.components.Label;
	
	/**
	 * Common functions for GUI stuff
	 * 
	 * @author mstrum
	 * 
	 */
	public final class ViewUtil
	{
		public static const windowHeight:int = 400;
		public static const windowWidth:int = 700;
		public static const minComponentHeight:int = 24;
		public static const minComponentWidth:int = 24;
		
		public static function assignIcon(val:Boolean):Class
		{
			if (val)
				return ImageUtil.availableIcon;
			else
				return ImageUtil.crossIcon;
		}
		
		// Get labels
		public static function getLabel(text:String, bold:Boolean = false, fontSize:Number = NaN):Label
		{
			var l:Label = new Label();
			l.text = text;
			if(bold)
				l.setStyle("fontWeight", "bold");
			if(fontSize)
				l.setStyle("fontSize", fontSize);
			return l;
		}
		
		public static function viewDocument(document:String, title:String):void
		{
			var documentView:DocumentWindow = new DocumentWindow();
			documentView.title = title;
			documentView.Document = document;
			documentView.showWindow();
		}
		
		public static function viewDocuments(documents:Array, title:String):void
		{
			var documentsView:MultiDocumentWindow = new MultiDocumentWindow();
			documentsView.title = title;
			for each(var docInfo:Object in documents)
				documentsView.addDocument(docInfo.title, docInfo.document);
			documentsView.showWindow();
		}
		
		public static function getButtonFor(data:*):DataButton
		{
			if(data is LogMessage)
				return ViewUtil.getLogMessageButton(data);
			return null;
		}
		
		public static function getLogMessageButton(msg:LogMessage, handleClick:Boolean = true, useShortestMessage:Boolean = false):DataButton
		{
			var img:Class;
			if(msg.level != LogMessage.LEVEL_INFO)
				img = ImageUtil.errorIcon;
			else
				img = ImageUtil.rightIcon;
			
			var logButton:DataButton = new DataButton(
				useShortestMessage ? msg.ShortestTitle : msg.Title,
				StringUtil.shortenString(msg.message, 80, true),
				img,
				handleClick ? msg : null
			);
			logButton.data = msg;
			if(msg.level == LogMessage.LEVEL_FAIL)
				logButton.styleName = "failedStyle";
			else if(msg.level == LogMessage.LEVEL_WARNING)
				logButton.styleName = "inprogressStyle";
			
			return logButton;
		}
		
		public static function viewContentInWindow(content:AreaContent):void
		{
			var area:Area = new Area();
			var window:DefaultWindow = new DefaultWindow();
			area.window = window;
			window.title = content.title;
			window.showWindow();
			window.addElement(area);
			area.Root = content;
		}
		
		public static function viewLogMessage(msg:LogMessage):void
		{
			var msgWindow:LogMessageArea = new LogMessageArea();
			msgWindow.Message = msg;
			viewContentInWindow(msgWindow);
		}
		
		public static function viewAbout():void
		{
			var area:Area = new Area();
			var subarea:AboutArea = new AboutArea();
			var window:DefaultWindow = new DefaultWindow();
			window.maxHeight = 400;
			window.maxWidth = 600;
			area.window = window;
			window.title = subarea.title;
			window.showWindow();
			window.addElement(area);
			area.Root = subarea;
		}
	}
}