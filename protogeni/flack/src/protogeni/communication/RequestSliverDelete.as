﻿/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2008, 2009 University of Utah and the Flux Group.
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

package protogeni.communication
{
	import protogeni.resources.Slice;
	import protogeni.resources.Sliver;

	public class RequestSliverDelete extends Request
	{
		public function RequestSliverDelete(s:Sliver) : void
		{
			super("SliverDelete", "Deleting sliver on " + s.manager.Hrn + " for slice named " + s.slice.hrn, CommunicationUtil.deleteSlice);
			sliver = s;
			op.addField("slice_urn", sliver.slice.urn);
			op.addField("credentials", new Array(sliver.slice.credential));
			op.setUrl(sliver.manager.Url);
		}
		
		override public function complete(code : Number, response : Object) : *
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS)
			{
				sliver.removeOutsideReferences();
				if(sliver.slice.slivers.contains(sliver))
					sliver.slice.slivers.remove(sliver);
				var old:Slice = Main.geniHandler.CurrentUser.slices.getByUrn(sliver.slice.urn);
				if(old != null)
				{
					var oldSliver:Sliver = old.slivers.getByUrn(sliver.urn);
					if(oldSliver != null) {
						oldSliver.removeOutsideReferences();
						old.slivers.remove(old.slivers.getByUrn(sliver.urn));
					}
					Main.geniDispatcher.dispatchSliceChanged(old);
				}
				Main.geniDispatcher.dispatchSliceChanged(sliver.slice);
			}
			else
			{
				// problem removing??
			}
			
			return null;
		}
		
		public var sliver:Sliver;
	}
}
