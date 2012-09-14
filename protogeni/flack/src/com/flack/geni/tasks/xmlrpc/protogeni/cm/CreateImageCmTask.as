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

package com.flack.geni.tasks.xmlrpc.protogeni.cm
{
	import com.flack.geni.resources.virtual.Sliver;
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
		public function CreateImageCmTask(newSourceNode:VirtualNode, newImageName:String, newGlobal:Boolean = true)
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