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

package com.flack.shared.tasks.file
{
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.TaskError;
	import com.flack.shared.utils.StringUtil;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	
	/**
	 * Does NOT support being started by a task group, must be manually started due to security
	 * 
	 * Supports:
	 *  Loading a file the user specifies into data.
	 *  Saving value in data to a file the user specifies.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class FileTask extends Task
	{
		private static const LOADING:Boolean = false;
		private static const SAVING:Boolean = true;
		
		/**
		 * Filename that should be entered into the file dialog by default, if saving
		 */
		public var fileName:String = "";
		
		private var operation:Boolean;
		private var fileReference:FileReference;
		
		/**
		 * Saves if data given, loads otherwise
		 * 
		 * @param saveData Data to save
		 * 
		 */
		public function FileTask(saveData:* = null)
		{
			super(
				(saveData == null ? "Open file" : "Save file"),
				(saveData == null ? "Opens and reads data from a selected file" : "Saves data to a selected file")
			);
			
			fileReference = new FileReference();
			fileReference.addEventListener(Event.SELECT, onFileSelect);
			fileReference.addEventListener(Event.CANCEL, onFileCancel);
			fileReference.addEventListener(Event.COMPLETE, onFileComplete);
			fileReference.addEventListener(IOErrorEvent.IO_ERROR, onFileIoError);
			fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileSecurityError);
			
			data = saveData;
			operation = saveData != null;
		}
		
		/**
		 * MUST be called after a mouse click due to Flash security...
		 * 
		 * @param event Mouse-click event
		 * 
		 */
		public function startOperation(event:Event):void
		{
			super.start();
			
			try
			{
				if(operation)
					fileReference.save(data, fileName);
				else
					fileReference.browse([new FileFilter("All files (*.*)", "*.*")]);
			}
			catch(e:Error)
			{
				afterError(
					new TaskError(
						"Error: " + StringUtil.errorToString(e),
						TaskError.CODE_UNEXPECTED,
						e
					)
				);
			}
		}
		
		private function onFileSelect(event:Event):void
		{
			fileName = fileReference.name;
			if(operation == LOADING)
				fileReference.load();
		}
		
		private function onFileComplete(event:Event):void
		{
			if(operation == LOADING)
				data = fileReference.data.readUTFBytes(fileReference.data.length);
			afterComplete();
		}
		
		private function onFileCancel(event:Event):void
		{
			cancel();
		}
		
		private function onFileIoError(event:IOErrorEvent):void
		{
			afterError(
				new TaskError(
					"IO Error: " + event.text,
					TaskError.FAULT,
					event
				)
			);
		}
		
		private function onFileSecurityError(event:SecurityErrorEvent):void
		{
			afterError(
				new TaskError(
					"Security Error: " + event.text,
					TaskError.FAULT,
					event
				)
			);
		}
		
		override protected function runCleanup():void
		{
			fileReference.removeEventListener(Event.SELECT, onFileSelect);
			fileReference.removeEventListener(Event.CANCEL, onFileCancel);
			fileReference.removeEventListener(Event.COMPLETE, onFileComplete);
			fileReference.removeEventListener(IOErrorEvent.IO_ERROR, onFileIoError);
			fileReference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileSecurityError);
			fileReference = null;
		}
	}
}