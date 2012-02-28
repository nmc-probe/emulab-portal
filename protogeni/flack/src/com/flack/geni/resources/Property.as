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

package com.flack.geni.resources
{
	import com.flack.geni.resources.physical.PhysicalInterface;
	import com.flack.geni.resources.virtual.VirtualInterface;
	import com.flack.shared.utils.NetUtil;

	/**
	 * Property of path from a source interface to a destination interface (one way) in a link
	 * 
	 * @author mstrum
	 * 
	 */
	public class Property
	{
		/**
		 * VirtualInterface OR PhysicalInterface
		 */
		public var source:*;
		/**
		 * VirtualInterface OR PhysicalInterface
		 */
		public var destination:*;
		
		public var capacity:Number;
		public function get CapacityDescription():String
		{
			return NetUtil.kbsToString(capacity);
		}
		
		public var packetLoss:Number;
		public function get PacketLossDescription():String
		{
			return (packetLoss*100) + "%";
		}
		
		public var latency:Number;
		public function get LatencyDescription():String
		{
			return latency + "ms";
		}
		
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param newSource Source virtual or physical interface
		 * @param newDestination Destination virtual or physical interface
		 * @param newCapacity Capacity
		 * @param newPacketLoss Packet loss
		 * @param newLatency Latency
		 * 
		 */
		public function Property(newSource:* = null,
									 newDestination:* = null,
									 newCapacity:Number = 0,
									 newPacketLoss:Number = 0,
									 newLatency:Number = 0)
		{
			source = newSource;
			destination = newDestination;
			capacity = newCapacity;
			packetLoss = newPacketLoss;
			latency = newLatency;
		}
		
		public function toString():String
		{
			if(source is VirtualInterface)
				return "[Property\n\t\t\t\tSource="+(source as VirtualInterface).clientId+",\n\t\t\t\tDest="+(destination as VirtualInterface).clientId+",\n\t\t\t\tCapacity="+capacity+",\n\t\t\t\tPacketLoss="+packetLoss+",\n\t\t\t\tLatency="+latency+" /]";
			else
				return "[Property\n\t\t\t\tSource="+(source as PhysicalInterface).id.name+",\n\t\t\t\tDest="+(destination as PhysicalInterface).id.name+",\n\t\t\t\tCapacity="+capacity+",\n\t\t\t\tPacketLoss="+packetLoss+",\n\t\t\t\tLatency="+latency+" /]";
				
		}
	}
}