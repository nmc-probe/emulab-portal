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

package com.flack.geni.plugins.openflow
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	import com.flack.geni.resources.SliverTypes;
	
	public class Openflow implements Plugin
	{
		public function get Title():String { return "OpenFlow" };
		public function get Area():PluginArea { return null; };
		
		public function Openflow()
		{
			super();
		}
		
		public function init():void
		{
			var newProcessor:OpenflowRspecProcessor = new OpenflowRspecProcessor();
			SliverTypes.addRspecProcessInterface(newProcessor.namespace.uri, newProcessor);
		}
	}
}