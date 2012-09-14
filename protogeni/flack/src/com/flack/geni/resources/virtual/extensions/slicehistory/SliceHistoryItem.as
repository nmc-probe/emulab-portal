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

package com.flack.geni.resources.virtual.extensions.slicehistory
{
	/**
	 * Snapshot of a slice
	 * 
	 * @author mstrum
	 * 
	 */
	public class SliceHistoryItem
	{
		public var rspec:String;
		public var note:String;
		
		/**
		 * 
		 * @param newRspec RSPEC for the snapshot
		 * @param newNote Description of what action was taken to get to this state
		 * 
		 */
		public function SliceHistoryItem(newRspec:String = "",
										 newNote:String = "")
		{
			rspec = newRspec;
			note = newNote;
		}
	}
}