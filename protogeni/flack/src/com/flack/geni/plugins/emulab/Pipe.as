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

package com.flack.geni.plugins.emulab
{
	import com.flack.geni.resources.virtual.VirtualInterface;

	/**
	 * Pipe used within a delay node to edit network properties from one interface to another
	 * 
	 * @author mstrum
	 * 
	 */
	public class Pipe
	{
		public var src:VirtualInterface;
		public var dst:VirtualInterface;
		
		public var capacity:Number;
		public var latency:Number;
		public var packetLoss:Number;
		
		/**
		 * 
		 * @param newSource Source interface
		 * @param newDestination Destination interface
		 * @param newCapacity Capacity
		 * @param newLatency Latency
		 * @param newPacketLoss Packet loss
		 * 
		 */
		public function Pipe(newSource:VirtualInterface,
							 newDestination:VirtualInterface,
							 newCapacity:Number = NaN,
							 newLatency:Number = NaN,
							 newPacketLoss:Number = NaN)
		{
			src = newSource;
			dst = newDestination;
			capacity = newCapacity;
			latency = newLatency;
			packetLoss = newPacketLoss;
		}
	}
}