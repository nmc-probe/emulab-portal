/*
 * Copyright (c) 2008-2012 University of Utah and the Flux Group.
 * 
 * {{{GENIPUBLIC-LICENSE
 * 
 * GENI Public License
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and/or hardware specification (the "Work") to
 * deal in the Work without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Work, and to permit persons to whom the Work
 * is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Work.
 * 
 * THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
 * IN THE WORK.
 * 
 * }}}
 */

package com.flack.geni.tasks.xmlrpc.protogeni.cm
{
	import com.flack.geni.resources.virtual.AggregateSliver;
	import com.flack.geni.resources.virtual.VirtualNode;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.FlackEvent;
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.logging.Logger;
	import com.flack.shared.resources.IdnUrn;
	import com.flack.shared.utils.DateUtil;
	import com.flack.shared.utils.ViewUtil;
	
	import mx.controls.Alert;
	
	/**
	 * Renews the sliver until the given date
	 * 
	 * @author mstrum
	 * 
	 */
	public final class CreateImageCmTask extends ProtogeniXmlrpcTask
	{
		public var sourceNode:VirtualNode;
		public var imageName:String;
		public var global:Boolean;
		
		// Filled in on success.
		public var imageId:String;
		public var imageUrl:String;
		
		/**
		 * 
		 * @param renewSliver Sliver to renew
		 * @param newExpirationDate Desired expiration date
		 * 
		 */
		public function CreateImageCmTask(newSourceNode:VirtualNode,
										  newImageName:String,
										  newGlobal:Boolean = true)
		{
			super(
				newSourceNode.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_CREATEIMAGE,
				"Create image " + newImageName + " based on " + newSourceNode.clientId,
				"Creating image " + newImageName + " based on " + newSourceNode.clientId + " on slice named " + newSourceNode.slice.hrn,
				"Create image"
			);
			relatedTo.push(newSourceNode);
			relatedTo.push(newSourceNode.slice);
			relatedTo.push(newSourceNode.manager);
			sourceNode = newSourceNode;
			imageName = newImageName;
			global = newGlobal;
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sourceNode.slice.id.full);
			addNamedField("sliver_urn", sourceNode.id.full);
			addNamedField("imagename", imageName);
			addNamedField("credentials", [sourceNode.slice.credential.Raw]);
			if(!global)
				addNamedField("global", global);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				imageId = data[0];
				imageUrl = data[1];
				
				var logMessage:LogMessage =
					addMessage(
						"Image created",
						"Image " + imageName + " created! You will need these for future use:\n" + 
						"For the same manager, you can use id=" + imageId + "\n"+
						"For other managers, you can use url=" + imageUrl,
						LogMessage.LEVEL_INFO,
						LogMessage.IMPORTANCE_HIGH
					);
				ViewUtil.viewLogMessage(logMessage);
				
				super.afterComplete(addCompletedMessage);
			}
			else
			{
				Alert.show("Failed to create image " + imageName);
				faultOnSuccess();
			}
		}
	}
}