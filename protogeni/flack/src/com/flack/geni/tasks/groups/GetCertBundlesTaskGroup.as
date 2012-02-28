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

package com.flack.geni.tasks.groups
{
	import com.flack.shared.SharedMain;
	import com.flack.shared.logging.LogMessage;
	import com.flack.shared.tasks.ParallelTaskGroup;
	import com.flack.shared.tasks.Task;
	import com.flack.shared.tasks.http.JsHttpTask;
	
	/**
	 * Downloads and applies any certificate bundles needed
	 * 
	 * @author mstrum
	 * 
	 */
	public class GetCertBundlesTaskGroup extends ParallelTaskGroup
	{
		/**
		 * 
		 * @param extraBundleUrls List of bundle urls to include
		 * 
		 */
		public function GetCertBundlesTaskGroup(extraBundleUrls:Vector.<String> = null)
		{
			super(
				"Download cert bundles",
				"Downloads server certificate bundles"
			);
			
			add(
				new JsHttpTask(
					"http://www.emulab.net/rootca.bundle",
					"Download root bundle",
					"Downloads the root cert bundle"
				)
			);
			
			add(
				new JsHttpTask(
					"http://www.emulab.net/genica.bundle",
					"Download GENI bundle",
					"Downloads the GENI cert bundle"
				)
			);
			
			if(extraBundleUrls != null && extraBundleUrls.length > 0) {
				for each(var certUrl:String in extraBundleUrls) {
					add(
						new JsHttpTask(
							certUrl,
							"Download extra bundle",
							"Downloads an extra bundle"
						)
					);
				}
			}
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			combineAndApplyBundles();
			
			super.afterComplete(addCompletedMessage);
		}
		
		/**
		 * Combine all of the server cert bundles we recieved and use them
		 * 
		 */
		private function combineAndApplyBundles():void {
			var combinedBundle:String = "";
			for each(var bundleTask:Task in tasks.collection)
			{
				if(bundleTask.data != null)
					combinedBundle += bundleTask.data + "\n";
			}
			SharedMain.Bundle = combinedBundle;
			
			addMessage(
				"Bundles applied",
				combinedBundle,
				LogMessage.LEVEL_INFO,
				LogMessage.IMPORTANCE_HIGH
			);
		}
	}
}