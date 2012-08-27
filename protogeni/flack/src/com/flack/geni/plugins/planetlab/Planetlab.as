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

package com.flack.geni.plugins.planetlab
{
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.PluginArea;
	import com.flack.geni.resources.SliverTypes;
	
	public class Planetlab implements Plugin
	{
		public function get Title():String { return "Planetlab" };
		public function get Area():PluginArea { return null; };
		
		public function Planetlab()
		{
			super();
		}
		
		public function init():void
		{
			SliverTypes.addSliverTypeInterface(PlanetlabSliverType.TYPE_PLANETLAB_V1, new PlanetlabSliverType());
			SliverTypes.addSliverTypeInterface(PlanetlabSliverType.TYPE_PLANETLAB_V2, new PlanetlabSliverType());
			SliverTypes.addSliverTypeInterface(M1TinySliverType.TYPE_M1TINY, new M1TinySliverType());
			SliverTypes.addSliverTypeInterface(M1SmallSliverType.TYPE_M1SMALL, new M1SmallSliverType());
			SliverTypes.addSliverTypeInterface(M1MediumSliverType.TYPE_M1MEDIUM, new M1MediumSliverType());
			SliverTypes.addSliverTypeInterface(M1LargeSliverType.TYPE_M1LARGE, new M1LargeSliverType());
			SliverTypes.addSliverTypeInterface(M1XLargeSliverType.TYPE_M1XLARGE, new M1XLargeSliverType());
			SliverTypes.addSliverTypeInterface(M1WorkerSliverType.TYPE_M1WORKER, new M1WorkerSliverType());
		}
	}
}