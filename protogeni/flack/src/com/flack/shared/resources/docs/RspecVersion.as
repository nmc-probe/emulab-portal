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

package com.flack.shared.resources.docs
{
	/**
	 * Type information about an rspec format
	 * 
	 * @author mstrum
	 * 
	 */
	public class RspecVersion
	{
		// Types
		public static const TYPE_PROTOGENI:String = "protogeni";
		public static const TYPE_GENI:String = "geni";
		public static const TYPE_SFA:String = "sfa";
		public static const TYPE_ORCA:String = "orca";
		public static const TYPE_OPENFLOW:String = "openflow";
		public static const TYPE_ORBIT:String = "orbit";
		public static const TYPE_EMULAB:String = "emulab";
		public static const TYPE_INVALID:String = "invalid";
		public static function typeToShort(type:String):String
		{
			switch(type)
			{
				case TYPE_PROTOGENI: return"PG";
				case TYPE_GENI: return "GENI";
				case TYPE_SFA: return "SFA";
				case TYPE_ORCA: return "ORCA";
				case TYPE_OPENFLOW: return "OF";
				case TYPE_ORBIT: return "ORBIT";
				case TYPE_EMULAB: return "Emulab";
				case TYPE_INVALID:
				default:
					return "??";
			}
		}
		
		/**
		 * What type is the RSPEC? (ProtoGENI, GENI, etc.)
		 */
		public var type:String;
		[Bindable]
		public var version:Number;
		/**
		 * 
		 * @return Very short string representation (eg. PGv2)
		 * 
		 */
		public function get ShortString():String
		{
			return RspecVersion.typeToShort(type) + "v" + version.toString();
		}
		
		/**
		 * 
		 * @param newType Type of RSPEC
		 * @param newVersion RSPEC Version
		 * 
		 */
		public function RspecVersion(newType:String,
									 newVersion:Number = NaN)
		{
			type = newType;
			version = newVersion;
		}
		
		public function toString():String
		{
			return "[RspecVersion Type="+type+", Version="+version+"]";
		}
	}
}