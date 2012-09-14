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

package com.flack.geni.resources.docs
{
	/**
	 * Type information about a credential format
	 * 
	 * @author mstrum
	 * 
	 */
	public class GeniCredentialVersion
	{
		// Types
		public static const TYPE_SFA:String = "geni_sfa";
		public static const TYPE_ABAC:String = "geni_abac";
		public static const TYPE_UNKNOWN:String = "";
		public static function typeToShort(type:String):String
		{
			switch(type)
			{
				case TYPE_SFA: return"SFA";
				case TYPE_ABAC: return "ABAC";
				case TYPE_UNKNOWN: return "Unknown";
				default:
					return "??";
			}
		}
		
		public static function get Default():GeniCredentialVersion
		{
			return new GeniCredentialVersion(TYPE_SFA, 2);
		}
		
		/**
		 * What type is the credential? (SFA, ABAC, etc.)
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
			return GeniCredentialVersion.typeToShort(type) + "v" + version.toString();
		}
		
		/**
		 * 
		 * @param newType Type of credential
		 * @param newVersion Credential version
		 * 
		 */
		public function GeniCredentialVersion(newType:String,
									 newVersion:Number = NaN)
		{
			type = newType;
			version = newVersion;
		}
		
		public function toString():String
		{
			return "[GeniCredentialVersion Type="+type+", Version="+version+"]";
		}
	}
}