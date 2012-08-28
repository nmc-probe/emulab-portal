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

package com.flack.emulab.tasks.xmlrpc.experiment
{
	import com.flack.emulab.tasks.xmlrpc.EmulabXmlrpcTask;
	
	import flash.utils.Dictionary;
	
	public class EmulabExperimentStartExpTask extends EmulabXmlrpcTask
	{
		private var managerUrl:String = "";
		// required
		private var proj:String;
		private var exp:String;
		private var nsfilestr:String;
		// optional
		private var group:String = "";
		private var batch:Boolean = true;
		private var description:String = "";
		private var swappable:Boolean = true;
		private var noSwapReason:String = "";
		private var idleSwap:int = -1;
		private var idleSwapReason:String = "";
		private var maxDuration:int = 0;	// minutes before unconditionally swapped
		private var noSwapIn:Boolean = false;
		public function EmulabExperimentStartExpTask(newProj:String,
													 newExp:String,
													 newNsfilestr:String,
													 newManagerUrl:String = "https://boss.emulab.net:3069/usr/testbed")
		{                                                                   
			super(
				newManagerUrl,
				EmulabXmlrpcTask.MODULE_EXPERIMENT,
				EmulabXmlrpcTask.METHOD_STARTEXP,
				"Get number of used nodes @ " + newManagerUrl,
				"Getting node availability at " + newManagerUrl,
				"# Nodes Used"
			);
			managerUrl = newManagerUrl;
			proj = newProj;
			exp = newExp;
			nsfilestr = newNsfilestr;
		}
		
		override protected function createFields():void
		{
			addOrderedField(version);
			var args:Dictionary = new Dictionary();
			args["proj"] = proj;
			args["exp"] = exp;
			args["nsfilestr"] = nsfilestr;
			// optional
			// group
			// batch
			// description
			// swappable
			// noswap_reason
			// idleswap
			// noidleswap_reason
			// max_duration
			// noswapin
			addOrderedField(args);
		}
		
		override protected function afterComplete(addCompletedMessage:Boolean=false):void
		{
			if (code == EmulabXmlrpcTask.CODE_SUCCESS)
			{
				super.afterComplete(addCompletedMessage);
			}
			else
				faultOnSuccess();
		}
	}
}