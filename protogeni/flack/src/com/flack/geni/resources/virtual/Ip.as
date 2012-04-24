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

package com.flack.geni.resources.virtual
{
	import com.flack.geni.resources.Extensions;

	/**
	 * IP Address
	 * 
	 * @author mstrum
	 * 
	 */
	public class Ip
	{
		public var address:String;
		public var netmask:String = "";
		public var type:String = "";
		public var unset:Boolean = true;
		
		public var extensions:Extensions = new Extensions();
		
		/**
		 * 
		 * @param newAddress String representation of the address
		 * 
		 */
		public function Ip(newAddress:String = "")
		{
			address = newAddress;
		}
		
		public function get Base():uint
		{
			var netmaskSubparts:Array = netmask.split('.');
			var baseSubparts:Array = netmask.split('.');
			
			var ipBase:uint = 0;
			for(var i:int = netmaskSubparts.length-1; i > -1; i--)
			{
				var netmaskSubpart:uint = new uint(netmaskSubparts[i]);
				var baseSubpart:uint = new uint(baseSubparts[i]);
				ipBase |= (((netmaskSubpart & baseSubpart) & 0xFF) << i*8);
			}
			
			return ipBase;
		}
		
		public function get Space():uint
		{
			var netmaskSubparts:Array = netmask.split('.');
			var baseSubparts:Array = netmask.split('.');
			
			var ipSpace:uint = 0;
			for(var i:int = netmaskSubparts.length-1; i > -1; i--)
			{
				var netmaskSubpart:uint = new uint(netmaskSubparts[i]);
				ipSpace |= (((~netmaskSubpart) & 0xFF) << i*8);
			}
			return ipSpace;
		}
	}
}