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
	import com.flack.geni.resources.docs.GeniCredential;
	import com.flack.geni.resources.virtual.Sliver;
	import com.flack.geni.tasks.process.ParseRequestManifestTask;
	import com.flack.geni.tasks.xmlrpc.protogeni.ProtogeniXmlrpcTask;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.resources.docs.Rspec;
	import com.flack.shared.utils.DateUtil;
	
	/**
	 * Creates a sliver based on the given RSPEC, usually generated for the entire slice.
	 * 
	 * @author mstrum
	 * 
	 */
	public final class CreateSliverCmTask extends ProtogeniXmlrpcTask
	{
		public var sliver:Sliver;
		public var request:Rspec;
		
		/**
		 * 
		 * @param newSliver Sliver to allocate resources in
		 * @param useRspec RSPEC used to allocate resources
		 * 
		 */
		public function CreateSliverCmTask(newSliver:Sliver,
										   useRspec:Rspec)
		{
			super(
				newSliver.manager.url,
				ProtogeniXmlrpcTask.MODULE_CM,
				ProtogeniXmlrpcTask.METHOD_CREATESLIVER,
				"Create sliver @ " + newSliver.manager.hrn,
				"Creating sliver on component manager " + newSliver.manager.hrn + " for slice named " + newSliver.slice.hrn,
				"Create Sliver"
			);
			relatedTo.push(newSliver);
			relatedTo.push(newSliver.slice);
			relatedTo.push(newSliver.manager);
			sliver = newSliver;
			
			request = useRspec;
			
			addMessage(
				"Waiting to create...",
				"A sliver will be created at " + sliver.manager.hrn,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
		
		override protected function runStart():void
		{
			sliver.markStaged();
			sliver.manifest = null;
			
			super.runStart();
		}
		
		override protected function createFields():void
		{
			addNamedField("slice_urn", sliver.slice.id.full);
			addNamedField("rspec", request.document);
			var keys:Array = [];
			for each(var key:String in sliver.slice.creator.keys) {
				keys.push({type:"ssh", key:key}); // XXX type
			}
			addNamedField("keys", keys);
			addNamedField("credentials", [sliver.slice.credential.Raw]);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == ProtogeniXmlrpcTask.CODE_SUCCESS)
			{
				sliver.credential = new GeniCredential(data[0], GeniCredential.TYPE_SLICE, sliver.manager);
				sliver.id = sliver.credential.TargetId;
				sliver.expires = sliver.credential.Expires;
				sliver.manifest = new Rspec(data[1],null,null,null, Rspec.TYPE_MANIFEST);
				
				addMessage(
					"Credential received",
					data[0],
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Manifest received",
					data[1],
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				addMessage(
					"Expires in " + DateUtil.getTimeUntil(sliver.expires),
					"Expires in " + DateUtil.getTimeUntil(sliver.expires),
					LogMessage.LEVEL_INFO,
					LogMessage.IMPORTANCE_HIGH
				);
				
				parent.add(new ParseRequestManifestTask(sliver, sliver.manifest));
				
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}