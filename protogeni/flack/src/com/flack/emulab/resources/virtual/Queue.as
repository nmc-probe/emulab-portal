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

package com.flack.emulab.resources.virtual
{
	public class Queue
	{
		public var gentle:int = 0;
		public var red:int = 0;
		public var queueInBytes:int = 0;
		public var limit:int = 50; // max limit is 1 megabyte if bytes or 100 slots if slots
		public var maxThresh:int = 15;
		public var thresh:int = 5;
		public var linterm:int = 10;
		public var qWeight:Number = .002;
		
		public function Queue()
		{
		}
	}
}