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
	import com.flack.geni.plugins.Plugin;
	import com.flack.geni.plugins.RspecProcessInterface;
	import com.flack.geni.plugins.SliverTypeInterface;
	import com.flack.geni.plugins.SliverTypePart;
	
	import flash.utils.Dictionary;

	public class SliverTypes
	{
		// V1
		public static var EMULAB_VNODE:String = "emulab-vnode";
		
		// Reference CM
		static public var QEMUPC:String = "qemu-pc"
		
		static public var XEN_VM:String = "xen-vm";
		
		private static var sliverTypeToInterface:Dictionary = new Dictionary();
		public static function addSliverTypeInterface(name:String, iface:SliverTypeInterface):void
		{
			sliverTypeToInterface[name] = iface;
		}
		public static function getSliverTypeInterface(name:String):SliverTypeInterface
		{
			return sliverTypeToInterface[name];
		}
		
		// XXX ugly, ugly, ugly ... but will do for now
		private static var rspecProcessToInterface:Dictionary = new Dictionary();
		public static function addRspecProcessInterface(name:String, iface:RspecProcessInterface):void
		{
			rspecProcessToInterface[name] = iface;
		}
		public static function getRspecProcessInterface(name:String):RspecProcessInterface
		{
			return rspecProcessToInterface[name];
		}
		
	}
}